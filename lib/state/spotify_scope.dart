// lib/state/spotify_scope.dart
import 'package:flutter/material.dart';
import 'spotify_session.dart';

class SpotifyScope extends InheritedNotifier<SpotifySession> {
  const SpotifyScope({
    super.key,
    required SpotifySession session,
    required Widget child,
  }) : super(notifier: session, child: child);

  static SpotifySession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SpotifyScope>();
    if (scope?.notifier == null) {
      throw StateError("SpotifyScope not found. Wrap your app with SpotifyScope.");
    }
    return scope!.notifier!;
  }
}
