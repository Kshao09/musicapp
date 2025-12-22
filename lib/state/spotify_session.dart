// lib/state/spotify_session.dart
import 'package:flutter/foundation.dart';
import 'package:spotify_sdk/spotify_sdk.dart';
import '../api/spotify_api.dart';

class SpotifySession extends ChangeNotifier {
  final String clientId;
  final String redirectUrl;

  SpotifySession({
    required this.clientId,
    required this.redirectUrl,
  });

  final SpotifyApi _api = SpotifyApi();

  // UI state
  String status = "Not logged in";
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  // Auth/profile
  bool _isLoggedIn = false;
  bool get isLoggedIn => _isLoggedIn;

  String? accessToken;
  DateTime? _tokenExpiresAt;

  String? displayName;
  String? email;
  String? avatarUrl;

  // Home data
  List<SpotifyPlaylistLite> myPlaylists = [];
  List<SpotifyTrackLite> recentlyPlayed = [];

  // Cache: playlistId -> tracks
  final Map<String, List<SpotifyTrackLite>> playlistTracksCache = {};

  bool _remoteConnected = false;

  static const _scope =
      "user-read-email,user-read-private,user-read-recently-played,playlist-read-private";

  Future<void> login() async {
    if (_isBusy) return;

    _setBusy(true, "Connecting to Spotify...");

    try {
      await SpotifySdk.connectToSpotifyRemote(
        clientId: clientId,
        redirectUrl: redirectUrl,
      );
      _remoteConnected = true;

      _setBusy(true, "Getting access token...");

      final token = await SpotifySdk.getAccessToken(
        clientId: clientId,
        redirectUrl: redirectUrl,
        scope: _scope,
      );

      accessToken = token;
      _tokenExpiresAt = DateTime.now().add(const Duration(minutes: 50));

      _setBusy(true, "Fetching profile (/me) ...");
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

    status = "Logged out";
    notifyListeners();

    try {
      await SpotifySdk.disconnect();
    } catch (_) {}
    _remoteConnected = false;
  }

  Future<void> loadHome() async {
    if (!_isLoggedIn) return;
    final token = await _ensureToken();
    if (token == null) return;

    _setBusy(true, "Loading home data...");

    try {
      final playlistsJson = await _api.getMyPlaylists(token, limit: 20, offset: 0);
      myPlaylists = playlistsJson
          .map((j) => SpotifyPlaylistLite.fromJson(j as Map<String, dynamic>))
          .toList();

      final recentJson = await _api.getRecentlyPlayed(token, limit: 10);
      recentlyPlayed = recentJson
          .map((j) => SpotifyTrackLite.fromJson(j as Map<String, dynamic>))
          .toList();

      status = "✅ Home data updated";
      notifyListeners();
    } catch (e) {
      status = "❌ Failed loading home: $e";
      notifyListeners();
    } finally {
      _setBusy(false, status);
    }
  }

  /// ✅ Load tracks of a playlist (Spotify Web API) + cache
  Future<List<SpotifyTrackLite>> loadPlaylistTracks(String playlistId) async {
    if (!_isLoggedIn) return const [];
    final token = await _ensureToken();
    if (token == null) return const [];

    // cache hit
    final cached = playlistTracksCache[playlistId];
    if (cached != null && cached.isNotEmpty) return cached;

    _setBusy(true, "Loading playlist tracks...");

    try {
      final tracksJson = await _api.getPlaylistTracks(token, playlistId, limit: 50, offset: 0);

      final tracks = tracksJson
          .whereType<Map<String, dynamic>>() // safe cast
          .map((j) => SpotifyTrackLite.fromJson(j))
          .toList();

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

  /// ✅ Play a Spotify URI (requires App Remote connected)
  Future<void> playUri(String uri) async {
    if (!_isLoggedIn) {
      status = "❌ Login first";
      notifyListeners();
      return;
    }
    if (uri.isEmpty) return;

    try {
      // If remote is not connected (or got disconnected), reconnect once.
      if (!_remoteConnected) {
        await SpotifySdk.connectToSpotifyRemote(clientId: clientId, redirectUrl: redirectUrl);
        _remoteConnected = true;
      }

      await SpotifySdk.play(spotifyUri: uri);
      status = "▶️ Playing";
      notifyListeners();
    } catch (e) {
      status = "❌ Play failed: $e";
      notifyListeners();
    }
  }

  /// ✅ Pause/Resume (these exist in spotify_sdk) :contentReference[oaicite:0]{index=0}
  Future<void> pause() async {
    if (!_isLoggedIn) return;
    try {
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
      await SpotifySdk.resume();
      status = "▶️ Playing";
      notifyListeners();
    } catch (e) {
      status = "❌ Resume failed: $e";
      notifyListeners();
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
    final artist = artists.isNotEmpty ? (artists.first["name"] ?? "Unknown") : "Unknown";

    final albumImages = (j["album"]?["images"] as List?) ?? const [];
    final imageUrl = albumImages.isNotEmpty ? albumImages.first["url"] as String? : null;

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
