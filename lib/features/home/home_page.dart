import 'package:flutter/material.dart';
import '../../data/demo_data.dart';
import '../../models/music.dart';
import '../../widgets/playlist_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/track_tile.dart';
import '../library/playlist_detail_page.dart';


class HomePage extends StatelessWidget {
  final ValueChanged<Track> onPlay;

  const HomePage({super.key, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    final demoData = DemoData();
    final playlists = demoData.playlists;
    final tracks = demoData.tracks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Recommended for you', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),

          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final playlist = playlists[i];
                return PlaylistCard(
                  playlist: playlist,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PlaylistDetailPage(
                          playlist: playlist,
                          onPlay: onPlay, // Pass the onPlay callback to the PlaylistDetailPage
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

          ...tracks.take(5).map((t) => TrackTile(track: t, onTap: () => onPlay(t))),
          const SizedBox(height: 12),

          const SectionHeader(title: 'Recently Played'),
          const SizedBox(height: 8),

          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: tracks.length.clamp(0, 8),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _MiniAlbumCard(
                title: tracks[i].title,
                subtitle: tracks[i].artist,
                onTap: () => onPlay(tracks[i]),
              ),
            ),
          ),
        ],
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
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
