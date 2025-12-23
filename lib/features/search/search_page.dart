import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../state/spotify_session.dart';
import '../../widgets/track_tile.dart';

class SearchPage extends StatefulWidget {
  final ValueChanged<Track> onPlay;
  const SearchPage({super.key, required this.onPlay});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _ctrl = TextEditingController();

  Timer? _debounce;
  bool _loading = false;
  String _query = '';

  List<Track> _results = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  Track _toTrack(SpotifyTrackLite t) {
    return Track(
      id: t.id,
      title: t.title,
      artist: t.artist,
      duration: t.duration,
      imageUrl: t.imageUrl,
      uri: t.uri,
    );
  }

  Future<void> _runSearch(String q) async {
    final session = SpotifyScope.of(context);

    final query = q.trim();
    setState(() {
      _query = query;
      _loading = true;
    });

    // Not logged in: fallback to demo local filter
    if (!session.isLoggedIn) {
      final demo = DemoData();
      final lower = query.toLowerCase();
      final tracks = demo.tracks.where((t) {
        if (lower.isEmpty) return true;
        return t.title.toLowerCase().contains(lower) || t.artist.toLowerCase().contains(lower);
      }).toList();

      setState(() {
        _results = tracks;
        _loading = false;
      });
      return;
    }

    if (query.isEmpty) {
      setState(() {
        _results = const [];
        _loading = false;
      });
      return;
    }

    final lite = await session.searchTracksLite(query, limit: 25, offset: 0);
    final tracks = lite.map(_toTrack).toList();

    if (!mounted) return;
    setState(() {
      _results = tracks;
      _loading = false;
    });
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      _runSearch(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: session.isLoggedIn ? 'Search Spotify tracks' : 'Search (demo mode)',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _onChanged,
              onSubmitted: _runSearch,
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _results.isEmpty
              ? Center(
                  child: Text(
                    _query.isEmpty ? "Type to search" : "No results",
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: _results.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = _results[i];
                    return TrackTile(
                      track: t,
                      onTap: () {
                        // ✅ Set queue so next/prev is deterministic
                        PlayerScope.of(context).playFromQueue(_results, i);

                        // ✅ Play selected item
                        widget.onPlay(t);
                      },
                    );
                  },
                ),
    );
  }
}
