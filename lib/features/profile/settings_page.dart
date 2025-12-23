import 'package:flutter/material.dart';
import '../../state/spotify_scope.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);

    void comingSoon() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Coming soon")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.tune),
                  title: const Text("Playback"),
                  subtitle: const Text("Queue, seek limitations, and controls"),
                  onTap: comingSoon,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text("Appearance"),
                  subtitle: const Text("Theme / colors (later)"),
                  onTap: comingSoon,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text("Privacy"),
                  subtitle: const Text("Tokens & account info"),
                  onTap: comingSoon,
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Text(
              session.isLoggedIn
                  ? "Spotify: Connected"
                  : "Spotify: Not connected",
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Disconnect Spotify"),
              enabled: session.isLoggedIn && !session.isBusy,
              onTap: () async {
                await session.logout();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Disconnected")),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
