import 'package:flutter/material.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          ListTile(leading: Icon(Icons.favorite_border), title: Text('Liked Songs')),
          Divider(),
          ListTile(leading: Icon(Icons.playlist_play), title: Text('Playlists')),
          Divider(),
          ListTile(leading: Icon(Icons.download_outlined), title: Text('Downloads')),
        ],
      ),
    );
  }
}
