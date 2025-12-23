import 'package:flutter/material.dart';
import '../models/music.dart';
import '../state/spotify_scope.dart';

class TrackTile extends StatelessWidget {
  final Track track;
  final VoidCallback? onTap;

  const TrackTile({super.key, required this.track, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);

    // Warm saved status once (safe: session has guard)
    if (session.isLoggedIn && track.id.isNotEmpty) {
      session.warmSavedStatus(track.id);
    }

    return AnimatedBuilder(
      animation: session,
      builder: (context, _) {
        final saved = session.savedStatusOf(track.id) == true;

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

            // ✅ heart + play icon
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: saved ? "Unlike" : "Like",
                  onPressed: (!session.isLoggedIn || track.id.isEmpty)
                      ? null
                      : () async {
                          await session.toggleSaved(track.id);
                        },
                  icon: Icon(saved ? Icons.favorite : Icons.favorite_border),
                ),
                const Icon(Icons.play_arrow),
              ],
            ),
          ),
        );
      },
    );
  }
}
