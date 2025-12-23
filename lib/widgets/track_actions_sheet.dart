import 'package:flutter/material.dart';

import '../models/music.dart';
import '../state/player_scope.dart';
import '../state/custom_playlists_scope.dart';

Future<void> showTrackActionsSheet(BuildContext context, {required Track track}) async {
  final cs = Theme.of(context).colorScheme;

  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(track.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(height: 6),

              ListTile(
                leading: const Icon(Icons.queue_music),
                title: const Text("Add to queue"),
                onTap: () {
                  PlayerScope.of(context).enqueue(track);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Added to queue")),
                  );
                },
              ),

              ListTile(
                leading: const Icon(Icons.playlist_add),
                title: const Text("Add to custom playlist"),
                onTap: () async {
                  Navigator.pop(ctx);
                  await _showAddToPlaylistPicker(context, track);
                },
              ),

              const SizedBox(height: 6),
              Divider(color: cs.outlineVariant),
              const SizedBox(height: 6),

              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Close"),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showAddToPlaylistPicker(BuildContext context, Track track) async {
  final controller = CustomPlaylistsScope.of(context);

  await showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final playlists = controller.playlists;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Choose a playlist",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () async {
                          final name = await _promptForName(context, title: "New playlist name");
                          if (name == null) return;
                          final p = controller.create(name);
                          controller.addTrack(p.id, track);
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Added to ${p.name}")),
                            );
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("New"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (playlists.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text("No playlists yet. Tap “New” to create one."),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final p = playlists[i];
                        return ListTile(
                          leading: const Icon(Icons.playlist_play),
                          title: Text(p.name),
                          subtitle: Text("${p.tracks.length} songs"),
                          onTap: () {
                            controller.addTrack(p.id, track);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Added to ${p.name}")),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

Future<String?> _promptForName(BuildContext context, {required String title}) async {
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: "e.g. Gym Mix"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text("Create"),
          ),
        ],
      );
    },
  );

  final name = result?.trim();
  if (name == null || name.isEmpty) return null;
  return name;
}
