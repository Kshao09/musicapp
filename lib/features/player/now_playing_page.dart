// lib/features/player/now_playing_page.dart
import 'package:flutter/material.dart';
import '../../state/player_scope.dart';

class NowPlayingPage extends StatelessWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final player = PlayerScope.of(context);
    final song = player.current;

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: song == null
          ? const Center(child: Text('No song selected'))
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    height: 240,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(Icons.album, size: 96, color: cs.onPrimaryContainer),
                  ),
                  const SizedBox(height: 16),
                  Text(song.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(song.artist, style: TextStyle(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 20),
                  Slider(value: 0.2, onChanged: (_) {}),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: () {}, icon: const Icon(Icons.skip_previous), iconSize: 36),
                      const SizedBox(width: 8),
                      FilledButton(
                        onPressed: player.toggle,
                        child: Icon(player.isPlaying ? Icons.pause : Icons.play_arrow),
                      ),
                      const SizedBox(width: 8),
                      IconButton(onPressed: () {}, icon: const Icon(Icons.skip_next), iconSize: 36),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
