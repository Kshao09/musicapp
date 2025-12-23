import 'package:flutter/material.dart';

import '../../state/spotify_scope.dart';
import '../library/liked_songs_page.dart';
import '../../models/music.dart';
import '../../state/player_scope.dart';

import 'settings_page.dart';
import 'about_page.dart';
import 'listening_history_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);

    final name = session.displayName ?? (session.isLoggedIn ? "Spotify User" : "Not connected");
    final email = session.email;
    final avatarUrl = session.avatarUrl;

    void playTrack(Track t) {
      final player = PlayerScope.of(context);
      player.play(t);

      final uri = t.uri;
      if (session.isLoggedIn && uri != null && uri.isNotEmpty) {
        session.playUri(uri);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: session.isLoggedIn ? cs.secondaryContainer : cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Text(
                  session.isLoggedIn ? "Connected" : "Not connected",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: session.isLoggedIn ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage:
                      (avatarUrl != null && avatarUrl.isNotEmpty) ? NetworkImage(avatarUrl) : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Icon(Icons.person, size: 46, color: cs.onPrimaryContainer)
                      : null,
                ),
                if (session.isBusy)
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.20),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              session.isLoggedIn
                  ? ((email != null && email.isNotEmpty) ? email : "Logged in")
                  : "Connect Spotify to unlock search, playlists, and likes",
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (session.isLoggedIn || session.isBusy) ? null : session.login,
                    icon: const Icon(Icons.link),
                    label: Text(session.isBusy ? "Please wait..." : "Connect Spotify"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (!session.isLoggedIn || session.isBusy) ? null : session.logout,
                    icon: const Icon(Icons.logout),
                    label: const Text("Disconnect"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.refresh),
                    title: const Text("Refresh Library/Home"),
                    subtitle: const Text("Reload playlists + recently played"),
                    enabled: session.isLoggedIn && !session.isBusy,
                    onTap: () async {
                      await session.loadHome();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Home refreshed")),
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.favorite_border),
                    title: const Text("Open Liked Songs"),
                    subtitle: const Text("Your saved tracks"),
                    enabled: session.isLoggedIn,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => LikedSongsPage(onPlay: playTrack),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Status", style: TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  SelectableText(
                    session.status,
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // ✅ Menu
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SettingsPage()),
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: const Text('Listening History'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ListeningHistoryPage(onPlay: playTrack),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 0),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text('About'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
