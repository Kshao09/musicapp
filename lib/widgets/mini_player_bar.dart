import 'package:flutter/material.dart';
import '../state/player_scope.dart';

class MiniPlayerBar extends StatelessWidget {
  final VoidCallback? onTap;
  final VoidCallback? onToggle;

  const MiniPlayerBar({
    super.key,
    this.onTap,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final player = PlayerScope.of(context);
    final song = player.current;
    if (song == null) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.music_note, color: cs.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              IconButton(
                onPressed: onToggle,
                icon: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
