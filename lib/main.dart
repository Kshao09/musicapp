// lib/main.dart
import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'state/player_controller.dart';
import 'state/player_scope.dart';
import 'state/spotify_scope.dart';
import 'state/spotify_session.dart';

const clientId = "2bceff485b9341d2b1d2fa89197b7d07";
const redirectUrl = "musicapp-login://callback";

void main() => runApp(const MusicApp());

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    final spotify = SpotifySession(clientId: clientId, redirectUrl: redirectUrl);
    final player = PlayerController();

    return PlayerScope(
      controller: player,
      child: SpotifyScope(
        session: spotify,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: const AppShell(),
        ),
      ),
    );
  }
}
