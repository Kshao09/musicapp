import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/music.dart';

class CustomPlaylist {
  final String id;
  String name;
  final List<Track> tracks;

  CustomPlaylist({
    required this.id,
    required this.name,
    List<Track>? tracks,
  }) : tracks = tracks ?? [];
}

class CustomPlaylistsController extends ChangeNotifier {
  // Keep SharedPrefs as backup/migration, but primary storage is a JSON file.
  static const String _prefsKey = 'custom_playlists_v1';
  static const String _fileName = 'custom_playlists.json';

  final List<CustomPlaylist> _playlists = [];
  List<CustomPlaylist> get playlists => List.unmodifiable(_playlists);

  bool _hydrated = false;
  bool _pendingSave = false;
  Timer? _saveDebounce;

  File? _storeFile;

  Future<void> load() async {
    if (_hydrated) return;

    try {
      // Create/locate file
      final dir = await getApplicationDocumentsDirectory();
      _storeFile = File('${dir.path}/$_fileName');

      String? raw;

      // 1) Prefer file
      if (await _storeFile!.exists()) {
        raw = await _storeFile!.readAsString();
      }

      // 2) Fallback to prefs (migration)
      raw ??= (await SharedPreferences.getInstance()).getString(_prefsKey);

      if (raw != null && raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          _playlists.clear();
          for (final item in decoded) {
            final p = _playlistFromJson(item);
            if (p != null) _playlists.add(p);
          }
        }
      }
    } catch (_) {
      // If anything fails, start empty (don’t crash).
    } finally {
      _hydrated = true;
      notifyListeners();

      // If any save was requested before load finished, flush now.
      if (_pendingSave) {
        _pendingSave = false;
        _scheduleSave(immediate: true);
      }
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    super.dispose();
  }

  CustomPlaylist? byId(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  String _trackKey(Track t) {
    final u = t.uri;
    if (u != null && u.isNotEmpty) return u;
    return t.id.isNotEmpty ? t.id : "${t.title}|${t.artist}|${t.duration.inMilliseconds}";
  }

  // ---------- CRUD ----------
  CustomPlaylist create(String name) {
    final trimmed = name.trim();
    final finalName = trimmed.isEmpty ? "New Playlist" : trimmed;

    final p = CustomPlaylist(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: finalName,
    );

    _playlists.insert(0, p);
    notifyListeners();
    _scheduleSave(immediate: true); // ✅ important: sync file write
    return p;
  }

  void rename(String playlistId, String newName) {
    final p = byId(playlistId);
    if (p == null) return;

    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    p.name = trimmed;
    notifyListeners();
    _scheduleSave(immediate: true);
  }

  void delete(String playlistId) {
    _playlists.removeWhere((p) => p.id == playlistId);
    notifyListeners();
    _scheduleSave(immediate: true);
  }

  bool addTrack(String playlistId, Track track, {bool dedupe = true}) {
    final p = byId(playlistId);
    if (p == null) return false;

    if (dedupe) {
      final k = _trackKey(track);
      final exists = p.tracks.any((t) => _trackKey(t) == k);
      if (exists) return false;
    }

    p.tracks.add(track);
    notifyListeners();
    _scheduleSave(immediate: true);
    return true;
  }

  bool removeTrack(String playlistId, Track track) {
    final p = byId(playlistId);
    if (p == null) return false;

    final k = _trackKey(track);
    final before = p.tracks.length;
    p.tracks.removeWhere((t) => _trackKey(t) == k);

    final changed = p.tracks.length != before;
    if (changed) {
      notifyListeners();
      _scheduleSave(immediate: true);
    }
    return changed;
  }

  // ✅ Reorder support
  void moveTrack(String playlistId, int oldIndex, int newIndex) {
    final p = byId(playlistId);
    if (p == null) return;

    if (oldIndex < 0 || oldIndex >= p.tracks.length) return;
    if (newIndex < 0 || newIndex > p.tracks.length) return;

    if (newIndex > oldIndex) newIndex -= 1;

    final item = p.tracks.removeAt(oldIndex);
    p.tracks.insert(newIndex, item);

    notifyListeners();
    _scheduleSave(); // debounce is fine for drag
  }

  // ---------- Export / Import ----------
  String exportJsonString({bool pretty = true}) {
    final data = _playlists.map(_playlistToJson).toList();
    return pretty
        ? const JsonEncoder.withIndent("  ").convert(data)
        : jsonEncode(data);
  }

  Future<bool> importFromJsonString(
    String raw, {
    bool replaceExisting = false,
    bool dedupeTracksInsidePlaylist = true,
  }) async {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return false;

      final imported = <CustomPlaylist>[];
      for (final item in decoded) {
        final p = _playlistFromJson(item);
        if (p != null) imported.add(p);
      }
      if (imported.isEmpty) return false;

      if (dedupeTracksInsidePlaylist) {
        for (final p in imported) {
          final seen = <String>{};
          p.tracks.removeWhere((t) => !seen.add(_trackKey(t)));
        }
      }

      if (replaceExisting) {
        _playlists
          ..clear()
          ..addAll(imported);
      } else {
        final existingIds = _playlists.map((p) => p.id).toSet();
        for (var i = 0; i < imported.length; i++) {
          if (existingIds.contains(imported[i].id)) {
            imported[i] = CustomPlaylist(
              id: DateTime.now().microsecondsSinceEpoch.toString(),
              name: imported[i].name,
              tracks: List<Track>.from(imported[i].tracks),
            );
          }
        }
        _playlists.insertAll(0, imported);
      }

      notifyListeners();
      _scheduleSave(immediate: true);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> clearAll() async {
    _playlists.clear();
    notifyListeners();

    try {
      // Remove file + prefs
      if (_storeFile != null && await _storeFile!.exists()) {
        await _storeFile!.delete();
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (_) {}
  }

  // ---------- Persistence ----------
  void _scheduleSave({bool immediate = false}) {
    if (!_hydrated) {
      _pendingSave = true;
      return;
    }

    if (immediate) {
      _saveDebounce?.cancel();
      _saveNow(); // fire-and-forget; file write happens sync before await
      return;
    }

    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 250), _saveNow);
  }

  Future<void> _saveNow() async {
    if (!_hydrated) return;

    // Build raw JSON once
    final raw = jsonEncode(_playlists.map(_playlistToJson).toList());

    try {
      // ✅ IMPORTANT: write synchronously first (survives hot restart)
      final f = _storeFile;
      if (f != null) {
        f.writeAsStringSync(raw, flush: true);
      }
    } catch (_) {
      // ignore file write failure
    }

    try {
      // Optional backup
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, raw);
    } catch (_) {
      // ignore prefs failure
    }
  }

  Map<String, dynamic> _playlistToJson(CustomPlaylist p) => {
        "id": p.id,
        "name": p.name,
        "tracks": p.tracks.map(_trackToJson).toList(),
      };

  CustomPlaylist? _playlistFromJson(dynamic obj) {
    if (obj is! Map) return null;

    final id = obj["id"]?.toString();
    final name = obj["name"]?.toString();

    if (id == null || id.isEmpty) return null;
    final safeName = (name == null || name.trim().isEmpty) ? "Playlist" : name;

    final tracksRaw = obj["tracks"];
    final tracks = <Track>[];

    if (tracksRaw is List) {
      for (final t in tracksRaw) {
        final tr = _trackFromJson(t);
        if (tr != null) tracks.add(tr);
      }
    }

    return CustomPlaylist(id: id, name: safeName, tracks: tracks);
  }

  Map<String, dynamic> _trackToJson(Track t) => {
        "id": t.id,
        "title": t.title,
        "artist": t.artist,
        "durationMs": t.duration.inMilliseconds,
        "imageUrl": t.imageUrl,
        "uri": t.uri,
      };

  Track? _trackFromJson(dynamic obj) {
    if (obj is! Map) return null;

    final id = obj["id"]?.toString() ?? "";
    final title = obj["title"]?.toString() ?? "";
    final artist = obj["artist"]?.toString() ?? "";
    final durationMs = (obj["durationMs"] is num) ? (obj["durationMs"] as num).toInt() : 0;
    final imageUrl = obj["imageUrl"]?.toString();
    final uri = obj["uri"]?.toString();

    if (title.isEmpty && artist.isEmpty) return null;

    return Track(
      id: id,
      title: title,
      artist: artist,
      duration: Duration(milliseconds: durationMs),
      imageUrl: imageUrl,
      uri: uri,
    );
  }
}
