import 'package:flutter/foundation.dart';
import '../models/music.dart';

class PlayerController extends ChangeNotifier {
  Track? _current;
  bool _isPlaying = false;

  List<Track> _queue = const [];
  int _queueIndex = -1;

  Track? get current => _current;
  bool get isPlaying => _isPlaying;

  List<Track> get queue => _queue;
  int get queueIndex => _queueIndex;

  bool get hasQueue =>
      _queue.isNotEmpty && _queueIndex >= 0 && _queueIndex < _queue.length;

  void setIsPlaying(bool value) {
    _isPlaying = value;
    notifyListeners();
  }

  int _findInQueue(Track t) {
    if (_queue.isEmpty) return -1;

    // Prefer URI match (best unique key)
    final uri = t.uri;
    if (uri != null && uri.isNotEmpty) {
      final i = _queue.indexWhere((x) => x.uri == uri);
      if (i != -1) return i;
    }

    // Fallback: id match
    if (t.id.isNotEmpty) {
      final i = _queue.indexWhere((x) => x.id == t.id && x.id.isNotEmpty);
      if (i != -1) return i;
    }

    return -1;
  }

  void play(Track track) {
    _current = track;
    _isPlaying = true;

    // ✅ IMPORTANT: don't nuke queue if this track is already inside it
    final idx = _findInQueue(track);
    if (idx != -1) {
      _queueIndex = idx;
    } else {
      // fallback queue = just this one track
      _queue = [track];
      _queueIndex = 0;
    }

    notifyListeners();
  }

  void enqueue(Track track, {bool dedupe = true}) {
    final key = (track.uri != null && track.uri!.isNotEmpty) ? track.uri! : track.id;

    final nextQueue = List<Track>.from(_queue);

    // If queue is empty but we have a current song, start queue with current
    if (nextQueue.isEmpty && _current != null) {
      nextQueue.add(_current!);
      _queueIndex = 0;
    }

    if (dedupe) {
      final exists = nextQueue.any((t) {
        final k = (t.uri != null && t.uri!.isNotEmpty) ? t.uri! : t.id;
        return k == key;
      });
      if (exists) {
        _queue = nextQueue;
        notifyListeners();
        return;
      }
    }

    nextQueue.add(track);
    _queue = nextQueue;

    // keep index valid
    if (_queueIndex < 0 && _queue.isNotEmpty) _queueIndex = 0;

    notifyListeners();
  }


  void playFromQueue(List<Track> tracks, int index) {
    if (tracks.isEmpty) return;
    final i = index.clamp(0, tracks.length - 1);

    _queue = List<Track>.from(tracks);
    _queueIndex = i;
    _current = _queue[_queueIndex];
    _isPlaying = true;

    notifyListeners();
  }

  void toggle() {
    if (_current == null) return;
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void stop() {
    _isPlaying = false;
    notifyListeners();
  }

  Track? jumpToQueueIndex(int index) {
    if (!hasQueue) return null;
    final i = index.clamp(0, _queue.length - 1);
    _queueIndex = i;
    _current = _queue[_queueIndex];
    _isPlaying = true;
    notifyListeners();
    return _current;
  }

  Track? nextLocal({bool wrap = false}) {
    if (!hasQueue) return null;
    var i = _queueIndex + 1;
    if (i >= _queue.length) {
      if (!wrap) return null;
      i = 0;
    }
    return jumpToQueueIndex(i);
  }

  Track? prevLocal({bool wrap = false}) {
    if (!hasQueue) return null;
    var i = _queueIndex - 1;
    if (i < 0) {
      if (!wrap) return null;
      i = _queue.length - 1;
    }
    return jumpToQueueIndex(i);
  }
}
