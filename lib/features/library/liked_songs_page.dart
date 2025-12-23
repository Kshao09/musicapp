import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../widgets/track_tile.dart';

class LikedSongsPage extends StatefulWidget {
  final ValueChanged<Track> onPlay;
  const LikedSongsPage({super.key, required this.onPlay});

  @override
  State<LikedSongsPage> createState() => _LikedSongsPageState();
}

class _LikedSongsPageState extends State<LikedSongsPage> {
  bool _loading = true;
  bool _didLoad = false;

  List<Track> _tracks = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoad) return;
    _didLoad = true;
    _refresh();
  }

  Future<void> _refresh() async {
    final session = SpotifyScope.of(context);

    if (!session.isLoggedIn) {
      setState(() {
        _tracks = const [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    // ✅ load liked songs from SpotifySession
    final lite = await session.loadLikedSongsLite(limit: 50, offset: 0);

    final tracks = lite
        .map(
          (t) => Track(
            id: t.id,
            title: t.title,
            artist: t.artist,
            duration: t.duration,
            imageUrl: t.imageUrl,
            uri: t.uri,
          ),
        )
        .toList();

    if (!mounted) return;
    setState(() {
      _tracks = tracks;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Liked Songs")),
      body: !session.isLoggedIn
          ? Center(
              child: Text(
                "Login to Spotify to view your liked songs.\n(Profile → Connect Spotify)",
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _loading
                  ? ListView(
                      children: [
                        const SizedBox(height: 260),
                        const Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : _tracks.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 240),
                            Center(
                              child: Text(
                                "No liked songs found.",
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: _tracks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final t = _tracks[i];
                            return TrackTile(
                              track: t,
                              onTap: () {
                                // ✅ queue enables next/prev through liked songs
                                PlayerScope.of(context).playFromQueue(_tracks, i);
                                widget.onPlay(t);
                              },
                            );
                          },
                        ),
            ),
    );
  }
}
