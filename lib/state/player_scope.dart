// lib/state/player_scope.dart
import 'package:flutter/material.dart';
import 'player_controller.dart';

class PlayerScope extends InheritedNotifier<PlayerController> {
  const PlayerScope(
    {
      super.key,
      required PlayerController controller, 
      required Widget child
    }) : super(notifier: controller, child: child);

  static PlayerController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PlayerScope>();
    if (scope?.notifier == null) {
      throw StateError('PlayerScope not found. Wrap your app with PlayerScope.');
    }
    return scope!.notifier!;
  }
}
