import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../state/spotify_session.dart';
import '../../widgets/track_tile.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOnce();
  }

  bool _didLoad = false;
  Future<void> _loadOnce() async {
    if (_didLoad) return;
    _didLoad = true;

    final session = SpotifyScope.of(context);

    setState(() => _loading = true);
    final lite = await session.loadPlaylistTracks(widget.playlist.id);
    final tracks = lite.map(_toTrack).toList();

    if (mounted) {
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final player = PlayerScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tracks.isEmpty
              ? Center(
                  child: Text(
                    "No tracks found.",
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _tracks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final t = _tracks[i];
                    return TrackTile(
                      track: t,
                      onTap: () {
                        // ✅ THIS is the fix for "Next becomes random":
                        // Set the in-app queue first, then play the selected item.
                        player.playFromQueue(_tracks, i);
                        widget.onPlay(t);
                      },
                    );
                  },
                ),
    );
  }
}
