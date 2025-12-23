import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/music.dart';
import '../../state/custom_playlists_scope.dart';
import 'custom_playlist_detail_page.dart';
import '../../state/custom_playlists_controller.dart';


class CustomPlaylistsPage extends StatelessWidget {
  final ValueChanged<Track> onPlay;
  const CustomPlaylistsPage({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = CustomPlaylistsScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Playlists"),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final name = await _promptForName(context);
              if (name == null) return;
              controller.create(name);
            },
          ),
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == "export") {
                final json = controller.exportJsonString(pretty: true);
                await Clipboard.setData(ClipboardData(text: json));
                if (context.mounted) {
                  await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Exported"),
                      content: const Text("Playlist JSON copied to clipboard."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
                      ],
                    ),
                  );
                }
              } else if (v == "import") {
                await _importDialog(context, controller);
              } else if (v == "clear") {
                final ok = await _confirm(context, "Clear all custom playlists?");
                if (ok == true) {
                  await controller.clearAll();
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: "export", child: Text("Export (copy JSON)")),
              PopupMenuItem(value: "import", child: Text("Import (paste JSON)")),
              PopupMenuDivider(),
              PopupMenuItem(value: "clear", child: Text("Clear all")),
            ],
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final playlists = controller.playlists;

          if (playlists.isEmpty) {
            return Center(
              child: Text(
                "No playlists yet.\nTap + to create one.",
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: playlists.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final p = playlists[i];
              return ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                tileColor: cs.surfaceContainerHighest,
                leading: const Icon(Icons.playlist_play),
                title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text("${p.tracks.length} songs"),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomPlaylistDetailPage(
                        playlistId: p.id,
                        onPlay: onPlay,
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<String?> _promptForName(BuildContext context) async {
    final ctrl = TextEditingController();
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create playlist"),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Playlist name"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text("Create")),
        ],
      ),
    );
    final name = res?.trim();
    if (name == null || name.isEmpty) return null;
    return name;
  }

  Future<bool?> _confirm(BuildContext context, String text) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm"),
        content: Text(text),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("OK")),
        ],
      ),
    );
  }

  Future<void> _importDialog(BuildContext context, CustomPlaylistsController controller) async {
    final ctrl = TextEditingController();
    bool replaceExisting = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text("Import playlists"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                minLines: 6,
                maxLines: 12,
                decoration: const InputDecoration(
                  hintText: "Paste exported JSON here…",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                value: replaceExisting,
                onChanged: (v) => setState(() => replaceExisting = v ?? false),
                title: const Text("Replace existing playlists"),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Import"),
            ),
          ],
        ),
      ),
    );

    if (ok != true) return;

    final raw = ctrl.text.trim();
    if (raw.isEmpty) return;

    final success = await controller.importFromJsonString(
      raw,
      replaceExisting: replaceExisting,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(success ? "Import complete" : "Import failed (invalid JSON)")),
    );
  }
}
