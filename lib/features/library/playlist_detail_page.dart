import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';

class PlaylistDetailPage extends StatelessWidget {
  final Playlist playlist;
  final ValueChanged<Track> onPlay;

  const PlaylistDetailPage({
    super.key,
    required this.playlist,
    required this.onPlay,
  });

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final player = PlayerScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(playlist.name)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(Icons.queue_music, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(playlist.subtitle, style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 6),
                        Text('${playlist.track.length} songs',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: playlist.track.length,
              separatorBuilder: (_, __) => Divider(color: cs.outlineVariant, height: 1),
              itemBuilder: (context, i) {
                final s = playlist.track[i];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Icon(Icons.music_note, color: cs.onPrimaryContainer),
                  ),
                  title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Text(_formatDuration(s.duration),
                      style: TextStyle(color: cs.onSurfaceVariant)),
                  onTap: () {
                    // ✅ Step 4: set queue so next/prev works
                    player.playFromQueue(playlist.track, i);
                    onPlay(s);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
