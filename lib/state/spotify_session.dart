import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import 'package:spotify_sdk/models/player_state.dart';
import 'package:spotify_sdk/models/image_uri.dart';
import 'package:spotify_sdk/enums/image_dimension_enum.dart';

import '../api/spotify_api.dart';

class SpotifySession extends ChangeNotifier {
  final String clientId;
  final String redirectUrl;

  SpotifySession({
    required this.clientId,
    required this.redirectUrl,
  });

  final SpotifyApi _api = SpotifyApi();

  String status = "Not logged in";
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? accessToken;
  DateTime? _tokenExpiresAt;

  String? displayName;
  String? email;
  String? avatarUrl;

  List<SpotifyPlaylistLite> myPlaylists = [];
  List<SpotifyTrackLite> recentlyPlayed = [];

  final Map<String, List<SpotifyTrackLite>> playlistTracksCache = {};

  bool _remoteConnected = false;

  // if seek fails once, we disable slider dragging
  bool canSeek = true;

  static const _scope =
      "user-read-email,user-read-private,user-read-recently-played,"
      "playlist-read-private,user-library-read,user-library-modify";

  // NOTE: subscribe doesn't emit continuous playbackPosition updates
  late final Stream<PlayerState> _playerStateStream =
      SpotifySdk.subscribePlayerState().asBroadcastStream();

  Stream<PlayerState> subscribePlayerState() => _playerStateStream;

  Future<void> connectRemoteIfNeeded() async {
    if (_remoteConnected) return;
    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      _remoteConnected = true;
    } catch (e) {
      status = "❌ Remote connect failed: $e";
      notifyListeners();
    }
  }

  Future<void> _ensureRemote() async {
    if (_remoteConnected) return;
    await SpotifySdk.connectToSpotifyRemote(
      clientId: clientId,
      redirectUrl: redirectUrl,
    );
    _remoteConnected = true;
  }

  // ✅ Seed/poll current state (needed because subscribe doesn't emit progress)
  Future<PlayerState?> getCurrentPlayerState() async {
    if (!_isLoggedIn) return null;
    try {
      await _ensureRemote();
      return await SpotifySdk.getPlayerState();
    } catch (_) {
      return null;
    }
  }

  // --- Saved cache ---
  final Map<String, bool> _savedCache = {};
  final Set<String> _savedInFlight = {};

  bool? savedStatusOf(String trackId) => _savedCache[trackId];

  Future<void> warmSavedStatus(String trackId) async {
    if (!_isLoggedIn) return;
    if (trackId.isEmpty) return;
    if (_savedCache.containsKey(trackId)) return;
    if (_savedInFlight.contains(trackId)) return;

    _savedInFlight.add(trackId);
    try {
      final token = await _ensureToken();
      if (token == null) return;

      final res = await _api.areTracksSaved(token, [trackId]);
      _savedCache[trackId] = res.isNotEmpty ? res.first : false;
      notifyListeners();
    } catch (_) {
      // ignore
    } finally {
      _savedInFlight.remove(trackId);
    }
  }

  Future<void> toggleSaved(String trackId) async {
    if (!_isLoggedIn) return;
    if (trackId.isEmpty) return;
    final token = await _ensureToken();
    if (token == null) return;

    // if unknown, warm first
    if (!_savedCache.containsKey(trackId)) {
      await warmSavedStatus(trackId);
    }

    final currentlySaved = _savedCache[trackId] == true;

    try {
      if (currentlySaved) {
        await _api.removeSavedTracks(token, [trackId]);
        _savedCache[trackId] = false;
        status = "Removed from Liked Songs";
      } else {
        await _api.saveTracks(token, [trackId]);
        _savedCache[trackId] = true;
        status = "Added to Liked Songs";
      }
      notifyListeners();
    } catch (e) {
      status = "❌ Like failed: $e";
      notifyListeners();
    }
  }

  // allow Settings page to toggle seek UI behavior
  void setCanSeek(bool value) {
    canSeek = value;
    notifyListeners();
  }

  void clearCaches() {
    playlistTracksCache.clear();
    _savedCache.clear();
    status = "Caches cleared";
    notifyListeners();
  }

  Future<void> login() async {
    if (_isBusy) return;

    _setBusy(true, "Connecting to Spotify.");

    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      _remoteConnected = true;

      _setBusy(true, "Getting access token.");

      final token = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scope: _scope,
      );

      accessToken = token;
      _tokenExpiresAt = DateTime.now().add(const Duration(minutes: 50));

      _setBusy(true, "Fetching profile (/me).");
      await _loadMe();

      _isLoggedIn = true;
      status = "✅ Logged in as: ${displayName ?? "unknown"}";
      notifyListeners();

      await loadHome();
    } catch (e) {
      _isLoggedIn = false;
      status = "❌ Error: $e";
      notifyListeners();
    } finally {
      _setBusy(false, status);
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    accessToken = null;
    _tokenExpiresAt = null;

    displayName = null;
    email = null;
    avatarUrl = null;

    myPlaylists = [];
    recentlyPlayed = [];
    playlistTracksCache.clear();

    canSeek = true;

    status = "Logged out";
    notifyListeners();

    try {
      await SpotifySdk.disconnect();
    } catch (_) {}
    _remoteConnected = false;
  }

  // ---------- DEDUPE HELPERS ----------
  List<SpotifyTrackLite> _dedupeTracks(List<SpotifyTrackLite> tracks) {
    final seen = <String>{};
    final out = <SpotifyTrackLite>[];

    for (final t in tracks) {
      final key = (t.uri != null && t.uri!.isNotEmpty)
          ? t.uri!
          : (t.id.isNotEmpty ? t.id : "${t.title}|${t.artist}|${t.duration.inMilliseconds}");

      if (seen.add(key)) out.add(t);
    }
    return out;
  }

  Future<void> loadHome() async {
    if (!_isLoggedIn) return;
    final token = await _ensureToken();
    if (token == null) return;

    _setBusy(true, "Loading home data.");

    try {
      final playlistsJson = await _api.getMyPlaylists(token, limit: 20, offset: 0);
      myPlaylists = playlistsJson
          .map((j) => SpotifyPlaylistLite.fromJson(j as Map<String, dynamic>))
          .toList();

      final recentJson = await _api.getRecentlyPlayed(token, limit: 30);

      // ✅ Dedupe here so UI never sees duplicates
      recentlyPlayed = _dedupeTracks(
        recentJson
            .map((j) => SpotifyTrackLite.fromJson(j as Map<String, dynamic>))
            .toList(),
      );

      status = "✅ Home data updated";
      notifyListeners();
    } catch (e) {
      status = "❌ Failed loading home: $e";
      notifyListeners();
    } finally {
      _setBusy(false, status);
    }
  }

  Future<List<SpotifyTrackLite>> loadPlaylistTracks(String playlistId) async {
    if (!_isLoggedIn) return const [];
    final token = await _ensureToken();
    if (token == null) return const [];

    final cached = playlistTracksCache[playlistId];
    if (cached != null && cached.isNotEmpty) return cached;

    _setBusy(true, "Loading playlist tracks.");

    try {
      final tracksJson = await _api.getPlaylistTracks(token, playlistId, limit: 50, offset: 0);

      final tracks = _dedupeTracks(
        tracksJson
            .whereType<Map<String, dynamic>>()
            .map((j) => SpotifyTrackLite.fromJson(j))
            .toList(),
      );

      playlistTracksCache[playlistId] = tracks;

      status = "✅ Playlist loaded";
      notifyListeners();
      return tracks;
    } catch (e) {
      status = "❌ Failed loading playlist: $e";
      notifyListeners();
      return const [];
    } finally {
      _setBusy(false, status);
    }
  }

  // ✅ Alias so your UI can call either name
  Future<List<SpotifyTrackLite>> loadPlaylistTracksLite(String playlistId) =>
      loadPlaylistTracks(playlistId);

  /// ✅ Load liked songs (saved tracks)
  Future<List<SpotifyTrackLite>> loadLikedSongsLite({
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_isLoggedIn) return const [];
    final token = await _ensureToken();
    if (token == null) return const [];

    _setBusy(true, "Loading liked songs.");

    try {
      final json = await _api.getLikedSongs(token, limit: limit, offset: offset);
      final tracks = _dedupeTracks(
        json
            .whereType<Map<String, dynamic>>()
            .map((j) => SpotifyTrackLite.fromJson(j))
            .toList(),
      );

      status = "✅ Liked songs loaded";
      notifyListeners();
      return tracks;
    } catch (e) {
      status = "❌ Failed loading liked songs: $e";
      notifyListeners();
      return const [];
    } finally {
      _setBusy(false, status);
    }
  }

  // --- Search state (optional) ---
  List<SpotifyTrackLite> lastSearch = [];
  String lastSearchQuery = "";

  /// ✅ Search tracks via Spotify Web API
  Future<List<SpotifyTrackLite>> searchTracksLite(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    if (!_isLoggedIn) return const [];
    final token = await _ensureToken();
    if (token == null) return const [];

    final q = query.trim();
    if (q.isEmpty) return const [];

    _setBusy(true, "Searching.");

    try {
      final json = await _api.searchTracks(token, q, limit: limit, offset: offset);
      final tracks = _dedupeTracks(
        json
            .whereType<Map<String, dynamic>>()
            .map((j) => SpotifyTrackLite.fromJson(j))
            .toList(),
      );

      lastSearch = tracks;
      lastSearchQuery = q;

      status = "✅ Search complete";
      notifyListeners();
      return tracks;
    } catch (e) {
      status = "❌ Search failed: $e";
      notifyListeners();
      return const [];
    } finally {
      _setBusy(false, status);
    }
  }

  Future<void> playUri(String uri) async {
    if (!_isLoggedIn) {
      status = "❌ Login first";
      notifyListeners();
      return;
    }
    if (uri.isEmpty) return;

    try {
      await _ensureRemote();
      await SpotifySdk.play(spotifyUri: uri);
      status = "▶️ Playing";
      notifyListeners();
    } catch (e) {
      status = "❌ Play failed: $e";
      notifyListeners();
    }
  }

  Future<void> pause() async {
    if (!_isLoggedIn) return;
    try {
      await _ensureRemote();
      await SpotifySdk.pause();
      status = "⏸ Paused";
      notifyListeners();
    } catch (e) {
      status = "❌ Pause failed: $e";
      notifyListeners();
    }
  }

  Future<void> resume() async {
    if (!_isLoggedIn) return;
    try {
      await _ensureRemote();
      await SpotifySdk.resume();
      status = "▶️ Playing";
      notifyListeners();
    } catch (e) {
      status = "❌ Resume failed: $e";
      notifyListeners();
    }
  }

  // ✅ Seek (returns success; on free it often fails, so we disable dragging after first failure)
  Future<bool> seekTo(Duration position) async {
    if (!_isLoggedIn) return false;
    try {
      await _ensureRemote();
      await SpotifySdk.seekTo(positionedMilliseconds: position.inMilliseconds);
      return true;
    } catch (e) {
      status = "❌ Seek failed: $e";
      canSeek = false; // free account commonly hits this
      notifyListeners();
      return false;
    }
  }

  Future<Uint8List?> getImageBytes(
    String imageUriRaw, {
    ImageDimension dimension = ImageDimension.large,
  }) async {
    if (!_isLoggedIn) return null;
    try {
      await _ensureRemote();
      return SpotifySdk.getImage(
        imageUri: ImageUri(imageUriRaw),
        dimension: dimension,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadMe() async {
    final token = await _ensureToken();
    if (token == null) return;

    final me = await _api.getMe(token);

    displayName = me["display_name"] ?? me["id"];
    email = me["email"];

    final images = (me["images"] as List?) ?? const [];
    if (images.isNotEmpty) {
      avatarUrl = images.first["url"];
    }
  }

  Future<String?> _ensureToken() async {
    if (accessToken == null) {
      status = "❌ No access token. Please login.";
      notifyListeners();
      return null;
    }

    if (_tokenExpiresAt != null && DateTime.now().isAfter(_tokenExpiresAt!)) {
      try {
        status = "Refreshing token...";
        notifyListeners();

        final token = await SpotifySdk.getAccessToken(
          clientId: clientId,
          redirectUrl: redirectUrl,
          scope: _scope,
        );

        accessToken = token;
        _tokenExpiresAt = DateTime.now().add(const Duration(minutes: 50));
      } catch (e) {
        status = "❌ Token refresh failed: $e";
        notifyListeners();
        return null;
      }
    }

    return accessToken;
  }

  void _setBusy(bool value, String msg) {
    _isBusy = value;
    status = msg;
    notifyListeners();
  }
}

// ----- Lite models -----
class SpotifyPlaylistLite {
  final String id;
  final String name;
  final String subtitle;
  final String? imageUrl;

  SpotifyPlaylistLite({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.imageUrl,
  });

  factory SpotifyPlaylistLite.fromJson(Map<String, dynamic> j) {
    final images = (j["images"] as List?) ?? const [];
    final imageUrl = images.isNotEmpty ? images.first["url"] as String? : null;

    final ownerName = j["owner"]?["display_name"];
    final description = (j["description"] as String?) ?? "";
    final subtitle = (ownerName != null && ownerName.toString().isNotEmpty)
        ? "by $ownerName"
        : (description.isNotEmpty ? description : "Playlist");

    return SpotifyPlaylistLite(
      id: j["id"],
      name: j["name"] ?? "Playlist",
      subtitle: subtitle,
      imageUrl: imageUrl,
    );
  }
}

class SpotifyTrackLite {
  final String id;
  final String title;
  final String artist;
  final Duration duration;
  final String? imageUrl;
  final String? uri;

  SpotifyTrackLite({
    required this.id,
    required this.title,
    required this.artist,
    required this.duration,
    required this.imageUrl,
    required this.uri,
  });

  factory SpotifyTrackLite.fromJson(Map<String, dynamic> j) {
    final artists = (j["artists"] as List?) ?? const [];
    final artist =
        artists.isNotEmpty ? (artists.first["name"] ?? "Unknown") : "Unknown";

    final albumImages = (j["album"]?["images"] as List?) ?? const [];
    final imageUrl =
        albumImages.isNotEmpty ? albumImages.first["url"] as String? : null;

    final ms = (j["duration_ms"] as int?) ?? 0;

    return SpotifyTrackLite(
      id: j["id"] ?? "",
      title: j["name"] ?? "Track",
      artist: artist.toString(),
      duration: Duration(milliseconds: ms),
      imageUrl: imageUrl,
      uri: j["uri"] as String?,
    );
  }
}
