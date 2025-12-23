import 'package:flutter/material.dart';
import 'custom_playlists_controller.dart';

class CustomPlaylistsScope extends InheritedNotifier<CustomPlaylistsController> {
  const CustomPlaylistsScope({
    super.key,
    required CustomPlaylistsController controller,
    required Widget child,
  }) : super(notifier: controller, child: child);

  static CustomPlaylistsController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<CustomPlaylistsScope>();
    if (scope?.notifier == null) {
      throw StateError("CustomPlaylistsScope not found. Wrap your app with CustomPlaylistsScope.");
    }
    return scope!.notifier!;
  }
}
