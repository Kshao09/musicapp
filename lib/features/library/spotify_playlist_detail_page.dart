import 'package:flutter/material.dart';

import '../../models/music.dart';
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
  String? _error;
  List<SpotifyTrackLite> _tracks = const [];

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOnce();
  }

  Future<void> _loadOnce() async {
    if (_started) return;
    _started = true;

    final session = SpotifyScope.of(context);

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final tracks = await session.loadPlaylistTracks(widget.playlist.id);
      setState(() {
        _tracks = tracks;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Track _toTrack(SpotifyTrackLite t) {
    return Track(
      id: t.id,
      title: t.title,
      artist: t.artist,
      duration: t.duration,
      uri: t.uri,
      imageUrl: t.imageUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.playlist.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text("❌ Failed loading tracks:\n$_error"),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _tracks.length,
                  separatorBuilder: (_, __) => Divider(color: cs.outlineVariant),
                  itemBuilder: (context, i) {
                    final t = _toTrack(_tracks[i]);
                    return TrackTile(
                      track: t,
                      onTap: () => widget.onPlay(t),
                    );
                  },
                ),
    );
  }
}
