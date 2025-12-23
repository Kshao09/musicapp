// lib/features/profile/settings_page.dart
import 'package:flutter/material.dart';

import '../../state/spotify_scope.dart';
import '../../state/theme_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);
    final theme = ThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: AnimatedBuilder(
        animation: Listenable.merge([session, theme]),
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ✅ Appearance (Dark Mode)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.palette_outlined),
                      title: const Text("Appearance"),
                      subtitle: Text(
                        "Choose Light / Dark / System",
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                    const Divider(height: 0),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: theme.mode,
                      title: const Text("System"),
                      onChanged: (v) => theme.setMode(v!),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: theme.mode,
                      title: const Text("Light"),
                      onChanged: (v) => theme.setMode(v!),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: theme.mode,
                      title: const Text("Dark"),
                      onChanged: (v) => theme.setMode(v!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Spotify section (your existing settings)
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.cloud_done_outlined),
                      title: const Text("Spotify"),
                      subtitle: Text(
                        session.isLoggedIn ? "Connected" : "Not connected",
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: session.isLoggedIn ? cs.secondaryContainer : cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: cs.outlineVariant),
                        ),
                        child: Text(
                          session.isLoggedIn ? "Connected" : "Offline",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: session.isLoggedIn ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text("Refresh Home"),
                      subtitle: const Text("Reload playlists + recently played"),
                      enabled: session.isLoggedIn && !session.isBusy,
                      onTap: () async {
                        await session.loadHome();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Home refreshed")),
                        );
                      },
                    ),
                    const Divider(height: 0),
                    ListTile(
                      leading: const Icon(Icons.logout),
                      title: const Text("Disconnect Spotify"),
                      subtitle: const Text("Logs out and disconnects remote"),
                      enabled: session.isLoggedIn && !session.isBusy,
                      onTap: () async {
                        await session.logout();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Disconnected")),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
