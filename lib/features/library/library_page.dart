import 'package:flutter/material.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../widgets/playlist_card.dart';
import '../library/liked_songs_page.dart';
import '../library/spotify_playlist_detail_page.dart';

import '../../state/custom_playlists_scope.dart';
import '../library/custom_playlists_page.dart';
import '../library/custom_playlist_detail_page.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final session = SpotifyScope.of(context);
    final custom = CustomPlaylistsScope.of(context);

    Future<void> refresh() async {
      if (session.isLoggedIn) {
        await session.loadHome();
      }
    }

    // ✅ IMPORTANT: don't overwrite queue if it's already set by playFromQueue(...)
    void playTrack(Track t) {
      final player = PlayerScope.of(context);

      // Only use fallback play() if there's no queue yet (demo mode or direct play)
      if (!player.hasQueue) {
        player.play(t);
      } else {
        player.setIsPlaying(true);
      }

      final uri = t.uri;
      if (session.isLoggedIn && uri != null && uri.isNotEmpty) {
        session.playUri(uri);
      }
    }

    // --- Build combined playlists list ---
    final customPlaylists = custom.playlists
        .map((p) => Playlist(
              id: p.id,
              name: p.name,
              subtitle: "${p.tracks.length} songs",
              imageUrl: p.tracks.isNotEmpty ? p.tracks.first.imageUrl : null,
              track: p.tracks,
            ))
        .toList();

    final spotifyPlaylists = session.myPlaylists;

    final totalPlaylists = customPlaylists.length +
        (session.isLoggedIn ? spotifyPlaylists.length : 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Custom playlists manager
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: const Text('My Playlists'),
              subtitle: Text(
                "${custom.playlists.length} playlists",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CustomPlaylistsPage(onPlay: playTrack),
                  ),
                );
              },
            ),
            const Divider(),

            // Liked Songs
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

            // ✅ One combined section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Playlists",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  "$totalPlaylists",
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (totalPlaylists == 0)
              Text(
                session.isLoggedIn
                    ? "No playlists found."
                    : "Create a custom playlist or login to Spotify.",
                style: TextStyle(color: cs.onSurfaceVariant),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalPlaylists,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  // ✅ First show custom playlists
                  if (i < customPlaylists.length) {
                    final playlist = customPlaylists[i];
                    return PlaylistCard(
                      playlist: playlist,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CustomPlaylistDetailPage(
                              playlistId: playlist.id,
                              onPlay: playTrack,
                            ),
                          ),
                        );
                      },
                    );
                  }

                  // ✅ Then show Spotify playlists (only if logged in)
                  final si = i - customPlaylists.length;
                  if (!session.isLoggedIn || si < 0 || si >= spotifyPlaylists.length) {
                    return const SizedBox.shrink();
                  }

                  final p = spotifyPlaylists[si];
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
                            onPlay: playTrack,
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
