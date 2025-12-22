// lib/features/profile/profile_page.dart
import 'package:flutter/material.dart';
import '../../state/spotify_scope.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SpotifyScope.of(context);

    final name = session.displayName ?? "Not logged in";
    final email = session.email;
    final avatarUrl = session.avatarUrl;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 44,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(
                      Icons.person,
                      size: 44,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    )
                  : null,
            ),

            const SizedBox(height: 12),

            Text(
              name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),

            const SizedBox(height: 6),

            if (session.isLoggedIn && email != null && email.isNotEmpty)
              Text(
                email,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              Text(
                session.isLoggedIn ? "Logged in" : "Not logged in",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),

            const SizedBox(height: 14),

            // Buttons row
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: (session.isLoggedIn || session.isBusy)
                        ? null
                        : session.login,
                    child: Text(session.isBusy ? "Please wait..." : "Login with Spotify"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: (!session.isLoggedIn || session.isBusy)
                        ? null
                        : session.logout,
                    child: const Text("Logout"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                session.status,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 18),

            // Menu card
            Card(
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.history),
                    title: Text('Listening History'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                  Divider(height: 0),
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('About'),
                    trailing: Icon(Icons.chevron_right),
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