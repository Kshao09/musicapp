import 'package:flutter/material.dart';
import 'package:spotify_sdk/models/player_state.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  bool _dragging = false;
  double _dragMs = 0;
  bool _didEnsureRemote = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didEnsureRemote) return;
    _didEnsureRemote = true;

    final session = SpotifyScope.of(context);
    session.connectRemoteIfNeeded();
  }

  String _fmtMs(int ms) {
    if (ms < 0) ms = 0;
    final d = Duration(milliseconds: ms);
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return "$m:${s.toString().padLeft(2, '0')}";
  }

  Widget _thumb(ColorScheme cs, Track t, {double size = 44}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: cs.secondaryContainer,
        child: (t.imageUrl != null && t.imageUrl!.isNotEmpty)
            ? Image.network(
                t.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.music_note, color: cs.onSecondaryContainer),
              )
            : Icon(Icons.music_note, color: cs.onSecondaryContainer),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final player = PlayerScope.of(context);
    final session = SpotifyScope.of(context);
    final song = player.current;

    // warm saved state for current song
    if (song != null && session.isLoggedIn && song.id.isNotEmpty) {
      session.warmSavedStatus(song.id);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: song == null
          ? const Center(child: Text('No song selected'))
          : StreamBuilder<PlayerState>(
              stream: session.subscribePlayerState(),
              builder: (context, snap) {
                final ps = snap.data;

                final bool isPlaying = ps != null ? !ps.isPaused : player.isPlaying;

                final int posMsInt = ps?.playbackPosition ?? 0;
                final int durMsInt = ps?.track?.duration ?? 0;

                final double maxMs = (durMsInt <= 0) ? 1.0 : durMsInt.toDouble();
                final double rawMs = _dragging ? _dragMs : posMsInt.toDouble();

                double clampedMs = rawMs;
                if (clampedMs < 0) clampedMs = 0;
                if (clampedMs > maxMs) clampedMs = maxMs;

                final int leftMs = clampedMs.round();
                final int rightMs = durMsInt;

                // build "Up Next" indices (wrap)
                final q = player.queue;
                final qi = player.queueIndex;
                final hasUpNext = q.length >= 2 && qi >= 0 && qi < q.length;

                List<int> upNextIdx = [];
                if (hasUpNext) {
                  final count = q.length - 1;
                  final take = count >= 3 ? 3 : count;
                  for (int k = 1; k <= take; k++) {
                    upNextIdx.add((qi + k) % q.length);
                  }
                }

                return AnimatedBuilder(
                  animation: session,
                  builder: (context, _) {
                    final bool canLike =
                        session.isLoggedIn && song.id.isNotEmpty;
                    final bool isLiked =
                        session.savedStatusOf(song.id) == true;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // artwork
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              height: 240,
                              width: double.infinity,
                              color: cs.primaryContainer,
                              child: (song.imageUrl != null &&
                                      song.imageUrl!.isNotEmpty)
                                  ? Image.network(song.imageUrl!, fit: BoxFit.cover)
                                  : Icon(Icons.album,
                                      size: 96, color: cs.onPrimaryContainer),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // title + like
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      song.title,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      song.artist,
                                      style: TextStyle(color: cs.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: isLiked ? "Unlike" : "Like",
                                onPressed: canLike
                                    ? () async {
                                        await session.toggleSaved(song.id);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              (session.savedStatusOf(song.id) == true)
                                                  ? "Added to Liked Songs"
                                                  : "Removed from Liked Songs",
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // slider
                          Slider(
                            value: clampedMs,
                            max: maxMs,
                            onChanged: session.canSeek
                                ? (v) {
                                    setState(() {
                                      _dragging = true;
                                      _dragMs = v;
                                    });
                                  }
                                : null,
                            onChangeEnd: session.canSeek
                                ? (v) async {
                                    setState(() => _dragging = false);
                                    final ok = await session.seekTo(
                                      Duration(milliseconds: v.round()),
                                    );
                                    if (!ok && mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Seeking is disabled on free Spotify accounts / some contexts.",
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                : null,
                          ),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmtMs(leftMs),
                                    style: TextStyle(color: cs.onSurfaceVariant)),
                                Text(_fmtMs(rightMs),
                                    style: TextStyle(color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // transport
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous),
                                iconSize: 36,
                                onPressed: () async {
                                  final prev = player.prevLocal(wrap: true);
                                  if (prev?.uri != null &&
                                      prev!.uri!.isNotEmpty) {
                                    await session.playUri(prev.uri!);
                                    player.setIsPlaying(true);
                                  }
                                },
                              ),
                              const SizedBox(width: 8),
                              FilledButton(
                                onPressed: () async {
                                  if (isPlaying) {
                                    await session.pause();
                                    player.setIsPlaying(false);
                                  } else {
                                    await session.resume();
                                    player.setIsPlaying(true);
                                  }
                                },
                                child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.skip_next),
                                iconSize: 36,
                                onPressed: () async {
                                  final next = player.nextLocal(wrap: true);
                                  if (next?.uri != null &&
                                      next!.uri!.isNotEmpty) {
                                    await session.playUri(next.uri!);
                                    player.setIsPlaying(true);
                                  }
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          if (!session.canSeek)
                            Text(
                              "Seeking is disabled by Spotify for this account/context.",
                              style: TextStyle(color: cs.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),

                          // ✅ Up Next
                          if (hasUpNext) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Up Next",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  "${q.length} in queue",
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            Container(
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: cs.outlineVariant),
                              ),
                              child: ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: upNextIdx.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 0,
                                  color: cs.outlineVariant,
                                ),
                                itemBuilder: (context, j) {
                                  final idx = upNextIdx[j];
                                  final t = q[idx];
                                  return ListTile(
                                    leading: _thumb(cs, t),
                                    title: Text(
                                      t.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      t.artist,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: const Icon(Icons.play_arrow),
                                    onTap: () async {
                                      // jump in queue + play on spotify
                                      player.jumpToQueueIndex(idx);
                                      if (t.uri != null && t.uri!.isNotEmpty) {
                                        await session.playUri(t.uri!);
                                        player.setIsPlaying(true);
                                      }
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
