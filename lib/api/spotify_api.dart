// lib/api/spotify_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class SpotifyApi {
  static const _base = "https://api.spotify.com/v1";

  Map<String, String> _headers(String token) => {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      };

  Future<Map<String, dynamic>> getTokenInfo(String token) async {
    final url = Uri.parse("https://api.spotify.com/v1/me");
    final res = await http.get(url, headers: _headers(token));
    return {"status": res.statusCode, "body": res.body};
  }

  Future<Map<String, dynamic>> getMe(String token) async {
    final url = Uri.parse("$_base/me");
    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMyPlaylists(String token, {int limit = 20, int offset = 0}) async {
    final url = Uri.parse("$_base/me/playlists?limit=$limit&offset=$offset");
    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (data["items"] as List?) ?? const [];
  }

  Future<List<dynamic>> getRecentlyPlayed(String token, {int limit = 10}) async {
    final url = Uri.parse("$_base/me/player/recently-played?limit=$limit");
    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data["items"] as List?) ?? const [];

    // each item has {"track": {...}}
    return items
        .map((e) => (e as Map<String, dynamic>)["track"])
        .where((t) => t != null)
        .toList();
  }

  Future<List<bool>> areTracksSaved(String token, List<String> ids) async {
    if (ids.isEmpty) return const [];
    final joined = ids.join(",");
    final url = Uri.parse("$_base/me/tracks/contains?ids=$joined");

    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
    final data = jsonDecode(res.body);
    return (data as List).map((e) => e == true).toList();
  }

  Future<void> saveTracks(String token, List<String> ids) async {
    if (ids.isEmpty) return;
    final joined = ids.join(",");
    final url = Uri.parse("$_base/me/tracks?ids=$joined");

    final res = await http.put(url, headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 201 && res.statusCode != 204) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
  }

  Future<void> removeSavedTracks(String token, List<String> ids) async {
    if (ids.isEmpty) return;
    final joined = ids.join(",");
    final url = Uri.parse("$_base/me/tracks?ids=$joined");

    final res = await http.delete(url, headers: _headers(token));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
  }

    /// ✅ Liked Songs (Saved Tracks)
  Future<List<dynamic>> getLikedSongs(
    String token, {
    int limit = 50,
    int offset = 0,
  }) async {
    final url = Uri.parse("$_base/me/tracks?limit=$limit&offset=$offset");
    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data["items"] as List?) ?? const [];

    // each item has {"track": {...}}
    return items
        .map((e) => (e as Map<String, dynamic>)["track"])
        .where((t) => t != null)
        .toList();
  }

  Future<List<dynamic>> getPlaylistTracks(
    String token,
    String playlistId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final url = Uri.parse("$_base/playlists/$playlistId/tracks?limit=$limit&offset=$offset");
    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (data["items"] as List?) ?? const [];

    // each item has {"track": {...}} (track can be null)
    return items
        .map((e) => (e as Map<String, dynamic>)["track"])
        .where((t) => t != null)
        .toList();
  }

  /// ✅ NEW: Search tracks (Spotify Web API)
  Future<List<dynamic>> searchTracks(
    String token,
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    final q = Uri.encodeQueryComponent(query.trim());
    final url = Uri.parse("$_base/search?q=$q&type=track&limit=$limit&offset=$offset");
    final res = await http.get(url, headers: _headers(token));
    if (res.statusCode != 200) {
      throw Exception("Spotify API ${res.statusCode}: $url\n${res.body}");
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final tracks = (data["tracks"] as Map<String, dynamic>?)?["items"] as List?;
    return tracks ?? const [];
  }
}
