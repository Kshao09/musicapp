// lib/features/home/home_page.dart
import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/music.dart';
import '../../state/spotify_scope.dart';
import '../../state/spotify_session.dart';
import '../../widgets/playlist_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_tile.dart';
import '../library/playlist_detail_page.dart';
import '../library/spotify_playlist_detail_page.dart';


class HomePage extends StatefulWidget {
  final ValueChanged<Track> onPlay;
  const HomePage({super.key, required this.onPlay});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _requestedInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Optional: if user is already logged in and home data is empty, fetch once.
    if (_requestedInitialLoad) return;
    final session = SpotifyScope.of(context);

    if (session.isLoggedIn &&
        !session.isBusy &&
        session.myPlaylists.isEmpty &&
        session.recentlyPlayed.isEmpty) {
      _requestedInitialLoad = true;
      session.loadHome();
    }
  }

  Track _toTrack(SpotifyTrackLite t) {
    return Track(
      id: t.id,
      title: t.title,
      artist: t.artist,
      duration: t.duration,
      uri: t.uri, // ✅ add this
    );
  }

  Playlist _toPlaylist(SpotifyPlaylistLite p) {
    // We only have playlist meta from /me/playlists (tracks not loaded yet)
    return Playlist(
      id: p.id,
      name: p.name,
      subtitle: p.subtitle,
      track: const [],
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = SpotifyScope.of(context);
    final demo = DemoData();

    final bool useSpotify = session.isLoggedIn;

    final List<Playlist> playlists = useSpotify
        ? session.myPlaylists.map(_toPlaylist).toList()
        : demo.playlists;

    final List<Track> tracks = useSpotify
        ? session.recentlyPlayed.map(_toTrack).toList()
        : demo.tracks;

    Future<void> refresh() async {
      if (!session.isLoggedIn) return;
      await session.loadHome();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          if (!session.isLoggedIn)
            TextButton(
              onPressed: session.isBusy ? null : session.login,
              child: Text(session.isBusy ? "..." : "Login"),
            ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Recommended for you',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),

            // --- Playlists row ---
            SizedBox(
              height: 180,
              child: playlists.isEmpty
                  ? _EmptyRowCard(
                      text: session.isLoggedIn
                          ? (session.isBusy ? "Loading your playlists..." : "No playlists found.")
                          : "Login to see your Spotify playlists.",
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: playlists.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final playlist = playlists[i];

                        return PlaylistCard(
                          playlist: playlist,
                          onTap: () {
                            if (useSpotify) {
                              final pLite = session.myPlaylists[i];

                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => SpotifyPlaylistDetailPage(
                                    playlist: pLite,
                                    onPlay: widget.onPlay,
                                  ),
                                ),
                              );
                              return;
                            }

                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => PlaylistDetailPage(
                                  playlist: playlist,
                                  onPlay: widget.onPlay,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),

            const SizedBox(height: 18),
            const SectionHeader(title: 'Quick Picks', actionText: 'See all'),
            const SizedBox(height: 8),

            // --- Quick Picks list (use recently played when logged in) ---
            if (!session.isLoggedIn)
              Text(
                "Login to see your real quick picks.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else if (session.isBusy && session.recentlyPlayed.isEmpty)
              Text(
                "Loading your recently played...",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else if (tracks.isEmpty)
              Text(
                "No recently played tracks yet.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ...tracks.take(5).map((t) => TrackTile(track: t, onTap: () => widget.onPlay(t))),

            const SizedBox(height: 12),
            const SectionHeader(title: 'Recently Played'),
            const SizedBox(height: 8),

            SizedBox(
              height: 120,
              child: tracks.isEmpty
                  ? _EmptyRowCard(
                      text: session.isLoggedIn
                          ? (session.isBusy ? "Loading..." : "Nothing played yet.")
                          : "Play something on Spotify and login to see it here.",
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: tracks.length.clamp(0, 8),
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _MiniAlbumCard(
                        title: tracks[i].title,
                        subtitle: tracks[i].artist,
                        onTap: () => widget.onPlay(tracks[i]),
                      ),
                    ),
            ),

            const SizedBox(height: 12),

            // Status (helpful while testing)
            if (session.status.isNotEmpty)
              Text(
                session.status,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}

class _MiniAlbumCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MiniAlbumCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.album, color: cs.onTertiaryContainer),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

class _EmptyRowCard extends StatelessWidget {
  final String text;
  const _EmptyRowCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Text(
        text,
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
    );
  }
}
