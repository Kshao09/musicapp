import 'package:flutter/material.dart';

import '../features/home/home_page.dart';
import '../features/search/search_page.dart';
import '../features/library/library_page.dart';
import '../features/profile/profile_page.dart';
import '../features/player/now_playing_page.dart';
import '../models/music.dart';
import '../widgets/mini_player_bar.dart';
import '../state/player_scope.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _play(Track t) {
    PlayerScope.of(context).play(t);
  }

  void _togglePlayPause() {
    PlayerScope.of(context).toggle();
  }

  void _openNowPlaying() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NowPlayingPage()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(onPlay: _play),
      SearchPage(onPlay: _play),
      const LibraryPage(),
      const ProfilePage(),
    ];

    final player = PlayerScope.of(context);

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (player.current != null) const MiniPlayerBar(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
              NavigationDestination(icon: Icon(Icons.search_outlined), selectedIcon: Icon(Icons.search), label: 'Search'),
              NavigationDestination(icon: Icon(Icons.library_music_outlined), selectedIcon: Icon(Icons.library_music), label: 'Library'),
              NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
            ],
          ),
        ],
      ),
    );
  }
}