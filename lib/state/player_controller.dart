// lib/state/player_controller.dart
import 'package:flutter/foundation.dart';
import '../models/music.dart';

class PlayerController extends ChangeNotifier {
  Track? _current;
  bool _isPlaying = false;

  Track? get current => _current;
  bool get isPlaying => _isPlaying;

  void play(Track track) {
    _current = track;
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
}
