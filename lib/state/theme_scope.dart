// lib/state/theme_scope.dart
import 'package:flutter/material.dart';
import 'theme_controller.dart';

class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    super.key,
    required ThemeController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    if (scope?.notifier == null) {
      throw StateError('ThemeScope not found. Wrap your app with ThemeScope.');
    }
    return scope!.notifier!;
  }
}
