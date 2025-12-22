// lib/app_shell.dart
import 'package:flutter/material.dart';

import '../features/home/home_page.dart';
import '../features/search/search_page.dart';
import '../features/library/library_page.dart';
import '../features/profile/profile_page.dart';
import '../features/player/now_playing_page.dart';
import '../models/music.dart';
import '../state/player_scope.dart';
import '../state/spotify_scope.dart';
import '../widgets/mini_player_bar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  // ✅ Step 3: update UI player + play on Spotify (if uri exists)
  void _play(Track t) {
    // update your UI player state (mini player / now playing page)
    PlayerScope.of(context).play(t);

    // play in Spotify app if we have a Spotify URI
    final session = SpotifyScope.of(context);
    final uri = t.uri;
    if (session.isLoggedIn && uri != null && uri.isNotEmpty) {
      session.playUri(uri);
    }
  }

  // ✅ Step 4: toggle play/pause on UI + Spotify
  Future<void> _togglePlayPause() async {
    final player = PlayerScope.of(context);
    final session = SpotifyScope.of(context);

    // Best effort: control Spotify playback if logged in
    if (session.isLoggedIn) {
      if (player.isPlaying) {
        await session.pause();
      } else {
        await session.resume();
      }
    }

    // Always update UI state too
    player.toggle();
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NowPlayingPage()),
    );
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
          if (player.current != null)
            MiniPlayerBar(
              onTap: _openNowPlaying,
              onToggle: _togglePlayPause,
            ),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.search_outlined),
                selectedIcon: Icon(Icons.search),
                label: 'Search',
              ),
              NavigationDestination(
                icon: Icon(Icons.library_music_outlined),
                selectedIcon: Icon(Icons.library_music),
                label: 'Library',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
