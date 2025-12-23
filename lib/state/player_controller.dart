import 'package:flutter/foundation.dart';
import '../models/music.dart';

class PlayerController extends ChangeNotifier {
  Track? _current;
  Track? get current => _current;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  // ✅ In-app queue (used for deterministic next/prev + wrap)
  List<Track> _queue = const [];
  List<Track> get queue => _queue;

  int _index = -1;
  int get index => _index;

  // Play a single track.
  // If it exists in the current queue, keep the queue and just jump index.
  // Otherwise, replace queue with just this one.
  void play(Track t) {
    final i = _queue.indexWhere((x) => x.id == t.id || (x.uri != null && x.uri == t.uri));
    if (i >= 0) {
      _index = i;
    } else {
      _queue = [t];
      _index = 0;
    }

    _current = t;
    _isPlaying = true;
    notifyListeners();
  }

  // ✅ Set an entire queue and start at a given index
  void playFromQueue(List<Track> tracks, int startIndex) {
    if (tracks.isEmpty) return;
    final safe = startIndex.clamp(0, tracks.length - 1);
    _queue = List<Track>.from(tracks);
    _index = safe;
    _current = _queue[_index];
    _isPlaying = true;
    notifyListeners();
  }

  // ✅ Deterministic next with wrap-around
  Track? nextLocal({bool wrap = true}) {
    if (_queue.isEmpty || _index < 0) return null;

    if (_index + 1 >= _queue.length) {
      if (!wrap) return null;
      _index = 0;
    } else {
      _index += 1;
    }

    _current = _queue[_index];
    _isPlaying = true;
    notifyListeners();
    return _current;
  }

  // ✅ Deterministic previous with wrap-around
  Track? prevLocal({bool wrap = true}) {
    if (_queue.isEmpty || _index < 0) return null;

    if (_index - 1 < 0) {
      if (!wrap) return null;
      _index = _queue.length - 1;
    } else {
      _index -= 1;
    }

    _current = _queue[_index];
    _isPlaying = true;
    notifyListeners();
    return _current;
  }

  void setIsPlaying(bool v) {
    _isPlaying = v;
    notifyListeners();
  }

  void toggle() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }
}
