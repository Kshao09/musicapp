import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../state/spotify_session.dart';
import '../../widgets/playlist_card.dart';
import '../library/liked_songs_page.dart';
import '../library/spotify_playlist_detail_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);

    Future<void> refresh() async {
      if (session.isLoggedIn) {
        await session.loadHome(); // refresh playlists + recently played
      }
    }

    // ✅ Play helper (same behavior as AppShell)
    void playTrack(Track t) {
      final player = PlayerScope.of(context);
      player.play(t);

      final uri = t.uri;
      if (session.isLoggedIn && uri != null && uri.isNotEmpty) {
        session.playUri(uri);
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ✅ Liked Songs opens page
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: const Text('Liked Songs'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LikedSongsPage(onPlay: playTrack),
                  ),
                );
              },
            ),
            const Divider(),

            const ListTile(
              leading: Icon(Icons.download_outlined),
              title: Text('Downloads'),
            ),
            const Divider(height: 24),

            // Playlists header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Playlists",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  session.isLoggedIn ? "${session.myPlaylists.length}" : "",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (!session.isLoggedIn)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Login to see your Spotify playlists",
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Go to Profile → Connect Spotify.",
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else if (session.myPlaylists.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: Text(
                    session.isBusy ? "Loading..." : "No playlists found.",
                    style: TextStyle(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: session.myPlaylists.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  final p = session.myPlaylists[i];

                  final playlist = Playlist(
                    id: p.id,
                    name: p.name,
                    subtitle: p.subtitle,
                    imageUrl: p.imageUrl,
                    track: const [],
                  );

                  return PlaylistCard(
                    playlist: playlist,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SpotifyPlaylistDetailPage(
                            playlist: p,
                            onPlay: playTrack, // ✅ pass the real play function
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
