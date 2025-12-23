import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../widgets/track_tile.dart';
import '../../widgets/track_actions_sheet.dart';

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

  // ✅ Step 5: unique tracks only
  List<Track> _uniqueTracks(List<Track> items) {
    final seen = <String>{};
    final out = <Track>[];
    for (final t in items) {
      final key = (t.uri != null && t.uri!.isNotEmpty)
          ? t.uri!
          : (t.id.isNotEmpty ? t.id : "${t.title}|${t.artist}|${t.duration.inMilliseconds}");
      if (seen.add(key)) out.add(t);
    }
    return out;
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

    final lite = await session.loadLikedSongsLite(limit: 50, offset: 0);

    final tracks = _uniqueTracks(
      lite
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
          .toList(),
    );

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
    final player = PlayerScope.of(context);

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
                      children: const [
                        SizedBox(height: 260),
                        Center(child: CircularProgressIndicator()),
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
                            return GestureDetector(
                              onLongPress: () => showTrackActionsSheet(context, track: t),
                              child: TrackTile(
                              track: t,
                              onTap: () {
                                // ✅ Step 4: queue enables next/prev
                                player.playFromQueue(_tracks, i);
                                widget.onPlay(t);
                              },
                            ));
                          },
                        ),
            ),
    );
  }
}
