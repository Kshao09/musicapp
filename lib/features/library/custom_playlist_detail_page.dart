import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/custom_playlists_scope.dart';
import '../../state/player_scope.dart';
import '../../widgets/track_actions_sheet.dart';

class CustomPlaylistDetailPage extends StatelessWidget {
  final String playlistId;
  final ValueChanged<Track> onPlay;

  const CustomPlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final playlists = CustomPlaylistsScope.of(context);
    final player = PlayerScope.of(context);

    return AnimatedBuilder(
      animation: playlists,
      builder: (context, _) {
        final p = playlists.byId(playlistId);

        if (p == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Playlist")),
            body: Center(
              child: Text("Playlist not found", style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(p.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () async {
                  final newName = await _promptRename(context, p.name);
                  if (newName == null) return;
                  playlists.rename(p.id, newName);
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await _confirmDelete(context, p.name);
                  if (ok != true) return;
                  playlists.delete(p.id);
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ],
          ),
          body: p.tracks.isEmpty
              ? Center(
                  child: Text(
                    "No songs yet.\nUse “Add to playlist” from a song’s actions.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                player.playFromQueue(p.tracks, 0);
                                onPlay(p.tracks[0]);
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text("Play"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: p.tracks.length,
                        onReorder: (oldIndex, newIndex) {
                          playlists.moveTrack(p.id, oldIndex, newIndex);
                        },
                        itemBuilder: (context, i) {
                          final t = p.tracks[i];
                          return Container(
                            key: ValueKey("${t.uri ?? t.id}_${i}"),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              tileColor: cs.surfaceContainerHighest,
                              leading: const Icon(Icons.music_note),
                              title: Text(t.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: Text(t.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: "Add to queue",
                                    icon: const Icon(Icons.queue_music),
                                    onPressed: () {
                                      player.enqueue(t);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Added to queue")),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    tooltip: "More",
                                    icon: const Icon(Icons.more_vert),
                                    onPressed: () => showTrackActionsSheet(context, track: t),
                                  ),
                                  IconButton(
                                    tooltip: "Remove",
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => playlists.removeTrack(p.id, t),
                                  ),
                                  const Icon(Icons.drag_handle),
                                ],
                              ),
                              onTap: () {
                                player.playFromQueue(p.tracks, i);
                                onPlay(t);
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<String?> _promptRename(BuildContext context, String current) async {
    final ctrl = TextEditingController(text: current);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Rename playlist"),
        content: TextField(controller: ctrl, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text("Save")),
        ],
      ),
    );
    final name = res?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete playlist?"),
        content: Text("Delete “$name” permanently?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete")),
        ],
      ),
    );
  }
}
