import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../state/spotify_session.dart';
import '../../widgets/track_tile.dart';
import '../../widgets/track_actions_sheet.dart';

class SpotifyPlaylistDetailPage extends StatefulWidget {
  final SpotifyPlaylistLite playlist;
  final ValueChanged<Track> onPlay;

  const SpotifyPlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.onPlay,
  });

  @override
  State<SpotifyPlaylistDetailPage> createState() => _SpotifyPlaylistDetailPageState();
}

class _SpotifyPlaylistDetailPageState extends State<SpotifyPlaylistDetailPage> {
  bool _loading = true;
  bool _didLoad = false;

  List<Track> _tracks = const [];

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

  // ✅ Step 5: unique tracks only (uri > id > fallback)
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOnce();
  }

  Future<void> _loadOnce() async {
    if (_didLoad) return;
    _didLoad = true;
    await _refresh(force: true);
  }

  Future<void> _refresh({bool force = false}) async {
    final session = SpotifyScope.of(context);

    if (!session.isLoggedIn) {
      if (!mounted) return;
      setState(() {
        _tracks = const [];
        _loading = false;
      });
      return;
    }

    if (mounted) setState(() => _loading = true);

    try {
      // If you implemented loadPlaylistTracksLite, you can call it here instead.
      final lite = await session.loadPlaylistTracks(widget.playlist.id);
      final tracks = _uniqueTracks(lite.map(_toTrack).toList());

      if (!mounted) return;
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final player = PlayerScope.of(context);
    final session = SpotifyScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: !session.isLoggedIn
          ? Center(
              child: Text(
                "Login to Spotify to view this playlist.\n(Profile → Connect Spotify)",
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            )
          : RefreshIndicator(
              onRefresh: () => _refresh(force: true),
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
                                "No tracks found.",
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: _tracks.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final t = _tracks[i];
                            return GestureDetector(
                              onLongPress: () => showTrackActionsSheet(context, track: t),
                              child: TrackTile(
                              track: t,
                              onTap: () {
                                // ✅ Step 4: queue first -> next/prev works
                                player.playFromQueue(_tracks, i);

                                // ✅ play selected
                                widget.onPlay(t);
                              },
                            ));
                          },
                        ),
            ),
    );
  }
}
