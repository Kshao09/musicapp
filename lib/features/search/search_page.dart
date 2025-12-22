import 'package:flutter/material.dart';
import '../../data/demo_data.dart';
import '../../models/music.dart';
import '../../widgets/track_tile.dart';

class SearchPage extends StatefulWidget {
  final ValueChanged<Track> onPlay;
  const SearchPage({super.key, required this.onPlay});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = DemoData();
    final tracks = demo.tracks.where((t) {
      final q = _query.trim().toLowerCase();
      if (q.isEmpty) return true;
      return t.title.toLowerCase().contains(q) || t.artist.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _ctrl,
              decoration: InputDecoration(
                hintText: 'Search tracks or artists',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: tracks.isEmpty
          ? const Center(child: Text('No results'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              itemCount: tracks.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final t = tracks[i];
                return TrackTile(track: t, onTap: () => widget.onPlay(t));
              },
            ),
    );
  }
}