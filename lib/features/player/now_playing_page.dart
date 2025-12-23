import 'package:flutter/material.dart';
import 'package:spotify_sdk/models/player_state.dart';

import '../../models/music.dart';
import '../../state/player_scope.dart';
import '../../state/spotify_scope.dart';
import '../../widgets/track_actions_sheet.dart';

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  bool _dragging = false;
  double _dragMs = 0;
  bool _didEnsureRemote = false;

  String? _lastSongKey;

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

  String _songKey(Track t) {
    final u = t.uri;
    if (u != null && u.isNotEmpty) return u;
    return t.id;
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

  Future<void> _playQueueIndex(int idx) async {
    final player = PlayerScope.of(context);
    final session = SpotifyScope.of(context);
    final q = player.queue;

    if (q.isEmpty || idx < 0 || idx >= q.length) return;

    final t = q[idx];
    final uri = t.uri;
    if (uri == null || uri.isEmpty) return;

    // 1) Ask Spotify to start the new song FIRST (prevents stale progress carryover)
    await session.playUri(uri);

    // 2) Now update your app's notion of "current"
    player.jumpToQueueIndex(idx);
    player.setIsPlaying(true);

    // 3) Reset local slider drag state
    if (mounted) {
      setState(() {
        _dragging = false;
        _dragMs = 0;
      });
    }
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

    // Reset slider state when song changes (so it never "inherits" old position visually)
    if (song != null) {
      final k = _songKey(song);
      if (_lastSongKey != k) {
        _lastSongKey = k;
        _dragging = false;
        _dragMs = 0;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Now Playing')),
      body: song == null
          ? const Center(child: Text('No song selected'))
          : StreamBuilder<PlayerState>(
              stream: session.subscribePlayerState(),
              builder: (context, snap) {
                final ps = snap.data;

                final bool isPlaying =
                    ps != null ? !ps.isPaused : player.isPlaying;

                // Only trust Spotify progress if Spotify's current track matches our current song.
                final psUri = ps?.track?.uri ?? '';
                final songUri = song.uri ?? '';
                final bool sameTrack =
                    songUri.isNotEmpty && psUri.isNotEmpty && psUri == songUri;

                final int posMsInt = sameTrack ? (ps?.playbackPosition ?? 0) : 0;

                // Prefer Spotify duration when it matches, otherwise fallback to your Track.duration.
                final int durFromPs =
                    sameTrack ? (ps?.track?.duration ?? 0) : 0;
                final int durFromSong = song.duration.inMilliseconds;
                final int durMsInt = (durFromPs > 0) ? durFromPs : durFromSong;

                final double maxMs =
                    (durMsInt <= 0) ? 1.0 : durMsInt.toDouble();
                final double rawMs =
                    _dragging ? _dragMs : posMsInt.toDouble();

                double clampedMs = rawMs.clamp(0, maxMs);

                final int leftMs = clampedMs.round();
                final int rightMs = durMsInt;

                // build "Up Next" indices (wrap)
                final q = player.queue;
                final qi = player.queueIndex;
                final hasUpNext =
                    q.length >= 2 && qi >= 0 && qi < q.length;

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
                                  ? Image.network(song.imageUrl!,
                                      fit: BoxFit.cover)
                                  : Icon(Icons.album,
                                      size: 96,
                                      color: cs.onPrimaryContainer),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // title + actions
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
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
                                      style: TextStyle(
                                          color: cs.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Add to Queue / Playlist
                              IconButton(
                                tooltip: "Add to queue / playlist",
                                onPressed: () =>
                                    showTrackActionsSheet(context, track: song),
                                icon: const Icon(Icons.playlist_add),
                              ),

                              IconButton(
                                tooltip: isLiked ? "Unlike" : "Like",
                                onPressed: canLike
                                    ? () async {
                                        await session.toggleSaved(song.id);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              (session.savedStatusOf(
                                                          song.id) ==
                                                      true)
                                                  ? "Added to Liked Songs"
                                                  : "Removed from Liked Songs",
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: Icon(isLiked
                                    ? Icons.favorite
                                    : Icons.favorite_border),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // slider (moves automatically when Spotify state updates)
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
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
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
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_fmtMs(leftMs),
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant)),
                                Text(_fmtMs(rightMs),
                                    style: TextStyle(
                                        color: cs.onSurfaceVariant)),
                              ],
                            ),
                          ),

                          const SizedBox(height: 18),

                          // transport (IMPORTANT: don't change queue index until Spotify starts new URI)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous),
                                iconSize: 36,
                                onPressed: () async {
                                  final q = player.queue;
                                  final qi = player.queueIndex;
                                  if (q.isEmpty || qi < 0) return;
                                  final prevIdx =
                                      (qi - 1 + q.length) % q.length;
                                  await _playQueueIndex(prevIdx);
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
                                child: Icon(isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.skip_next),
                                iconSize: 36,
                                onPressed: () async {
                                  final q = player.queue;
                                  final qi = player.queueIndex;
                                  if (q.isEmpty || qi < 0) return;
                                  final nextIdx = (qi + 1) % q.length;
                                  await _playQueueIndex(nextIdx);
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

                          // Up Next
                          if (hasUpNext) ...[
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
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
                                  style: TextStyle(
                                      color: cs.onSurfaceVariant),
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
                                physics:
                                    const NeverScrollableScrollPhysics(),
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
                                    trailing:
                                        const Icon(Icons.play_arrow),
                                    onTap: () async {
                                      await _playQueueIndex(idx);
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
