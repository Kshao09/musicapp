import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text("About")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Music App",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              "A Flutter music player UI + Spotify integration (App Remote + Web API).",
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: Text(
                "Note: On free Spotify accounts, seeking can be disabled depending on context.",
                style: TextStyle(color: cs.onSurfaceVariant),
              ),
            ),

            const SizedBox(height: 16),
            const Text("Features", style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text("• Home playlists + quick picks\n"
                "• Search\n"
                "• Library playlists\n"
                "• Liked Songs (read/write)\n"
                "• Now Playing with queue + Up Next"),
          ],
        ),
      ),
    );
  }
}
