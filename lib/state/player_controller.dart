// lib/state/player_controller.dart
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

  void play(Track track) {
    _current = track;
    _isPlaying = true;

    // fallback queue = just this one track (so UI stays consistent)
    _queue = [track];
    _queueIndex = 0;

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
