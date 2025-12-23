import 'package:flutter/material.dart';
import '../models/music.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;

  const TrackTile({super.key, required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 44,
            height: 44,
            color: cs.secondaryContainer,
            child: (track.imageUrl != null && track.imageUrl!.isNotEmpty)
                ? Image.network(
                    track.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Icon(Icons.music_note, color: cs.onSecondaryContainer),
                  )
                : Icon(Icons.music_note, color: cs.onSecondaryContainer),
          ),
        ),
        title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.play_arrow),
      ),
    );
  }
}
