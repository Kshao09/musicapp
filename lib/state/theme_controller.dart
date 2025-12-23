import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const _key = "theme_mode_v1";

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  bool _hydrated = false;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);

      _mode = switch (raw) {
        "light" => ThemeMode.light,
        "dark" => ThemeMode.dark,
        _ => ThemeMode.system,
      };

      _hydrated = true;
      notifyListeners();
    } catch (_) {
      _hydrated = true;
      notifyListeners();
    }
  }

  void setMode(ThemeMode m) {
    _mode = m;
    notifyListeners();
    _save();
  }

  void toggleLightDark() {
    setMode(_mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _save() async {
    if (!_hydrated) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = switch (_mode) {
        ThemeMode.light => "light",
        ThemeMode.dark => "dark",
        _ => "system",
      };
      await prefs.setString(_key, raw);
    } catch (_) {
      // ignore
    }
  }
}
