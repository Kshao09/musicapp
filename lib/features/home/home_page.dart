// lib/features/home/home_page.dart
import 'package:flutter/material.dart';

import '../../data/demo_data.dart';
import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../state/spotify_session.dart';
import '../../widgets/playlist_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_tile.dart';
import '../library/playlist_detail_page.dart';
import '../library/spotify_playlist_detail_page.dart';
import '../../widgets/track_actions_sheet.dart';
import '../../state/custom_playlists_scope.dart';
import '../library/custom_playlist_detail_page.dart';

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
      imageUrl: t.imageUrl,
      uri: t.uri,
    );
  }

  Playlist _toPlaylist(SpotifyPlaylistLite p) {
    return Playlist(
      id: p.id,
      name: p.name,
      subtitle: p.subtitle,
      imageUrl: p.imageUrl,
      track: const [],
    );
  }

  List<Track> _uniqueTracks(List<Track> items) {
    final seen = <String>{};
    final out = <Track>[];
    for (final t in items) {
      final key = (t.uri != null && t.uri!.isNotEmpty)
          ? t.uri!
          : (t.id.isNotEmpty ? t.id : "${t.title}|${t.artist}|${t.duration.inMilliseconds}");
      if (seen.add(key)) out.add(t);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final session = SpotifyScope.of(context);
    final player = PlayerScope.of(context);
    final demo = DemoData();
    final custom = CustomPlaylistsScope.of(context);

    final bool useSpotify = session.isLoggedIn;

    // Spotify/demo playlists
    final List<Playlist> playlists = useSpotify
        ? session.myPlaylists.map(_toPlaylist).toList()
        : demo.playlists;

    // ✅ Custom playlists -> renderable as PlaylistCard
    final customPlaylists = custom.playlists
        .map((p) => Playlist(
              id: p.id,
              name: p.name,
              subtitle: "${p.tracks.length} songs",
              imageUrl: p.tracks.isNotEmpty ? p.tracks.first.imageUrl : null,
              track: p.tracks,
            ))
        .toList();

    // ✅ Combined list shown in “Recommended for you”
    final combinedPlaylists = [...customPlaylists, ...playlists];

    final List<Track> rawTracks = useSpotify
        ? session.recentlyPlayed.map(_toTrack).toList()
        : demo.tracks;

    final List<Track> uniqueTracks = _uniqueTracks(rawTracks);
    final List<Track> quickPicks = uniqueTracks.take(5).toList();

    final quickKeys = quickPicks
        .map((t) => (t.uri != null && t.uri!.isNotEmpty)
            ? t.uri!
            : (t.id.isNotEmpty ? t.id : "${t.title}|${t.artist}|${t.duration.inMilliseconds}"))
        .toSet();

    final List<Track> recentCards = uniqueTracks
        .where((t) {
          final k = (t.uri != null && t.uri!.isNotEmpty)
              ? t.uri!
              : (t.id.isNotEmpty ? t.id : "${t.title}|${t.artist}|${t.duration.inMilliseconds}");
          return !quickKeys.contains(k);
        })
        .take(8)
        .toList();

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

            // --- Playlists row (custom + spotify/demo) ---
            SizedBox(
              height: 180,
              child: combinedPlaylists.isEmpty
                  ? _EmptyRowCard(
                      text: session.isLoggedIn
                          ? (session.isBusy ? "Loading your playlists..." : "No playlists found.")
                          : "Create a custom playlist or login to see Spotify playlists.",
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: combinedPlaylists.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final playlist = combinedPlaylists[i];

                        return PlaylistCard(
                          playlist: playlist,
                          onTap: () {
                            // ✅ Custom playlist
                            if (i < customPlaylists.length) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CustomPlaylistDetailPage(
                                    playlistId: playlist.id,
                                    onPlay: widget.onPlay,
                                  ),
                                ),
                              );
                              return;
                            }

                            // ✅ Spotify playlist (offset by custom length)
                            final offset = i - customPlaylists.length;
                            if (useSpotify) {
                              final pLite = session.myPlaylists[offset];
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

                            // ✅ Demo playlist
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
            else if (quickPicks.isEmpty)
              Text(
                "No recently played tracks yet.",
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              )
            else
              ...List.generate(quickPicks.length, (i) {
                final t = quickPicks[i];
                return GestureDetector(
                  onLongPress: () => showTrackActionsSheet(context, track: t),
                  child: TrackTile(
                    track: t,
                    onTap: () {
                      player.playFromQueue(quickPicks, i);
                      widget.onPlay(t);
                    },
                  ),
                );
              }),

            const SizedBox(height: 12),
            const SectionHeader(title: 'Recently Played'),
            const SizedBox(height: 8),

            SizedBox(
              height: 120,
              child: recentCards.isEmpty
                  ? _EmptyRowCard(
                      text: session.isLoggedIn
                          ? (session.isBusy ? "Loading..." : "Nothing played yet.")
                          : "Play something on Spotify and login to see it here.",
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentCards.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) => _MiniAlbumCard(
                        title: recentCards[i].title,
                        subtitle: recentCards[i].artist,
                        imageUrl: recentCards[i].imageUrl,
                        onTap: () {
                          player.playFromQueue(recentCards, i);
                          widget.onPlay(recentCards[i]);
                        },
                      ),
                    ),
            ),

            const SizedBox(height: 12),

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
  final String? imageUrl;
  final VoidCallback? onTap;

  const _MiniAlbumCard({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 44,
                height: 44,
                color: cs.primaryContainer,
                child: (imageUrl != null && imageUrl!.isNotEmpty)
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Icon(Icons.album, color: cs.onPrimaryContainer),
                      )
                    : Icon(Icons.album, color: cs.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurfaceVariant),
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
      child: Text(text, style: TextStyle(color: cs.onSurfaceVariant)),
    );
  }
}
