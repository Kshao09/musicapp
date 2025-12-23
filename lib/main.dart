// lib/main.dart
import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'state/player_controller.dart';
import 'state/player_scope.dart';
import 'state/spotify_scope.dart';
import 'state/spotify_session.dart';

import 'state/theme_controller.dart';
import 'state/theme_scope.dart';

const clientId = "2bceff485b9341d2b1d2fa89197b7d07";
const redirectUrl = "musicapp-login://callback";

void main() => runApp(const MusicApp());

class MusicApp extends StatelessWidget {
  const MusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Keep controllers/sessions created once for the life of the app.
    final spotify = SpotifySession(clientId: clientId, redirectUrl: redirectUrl);
    final player = PlayerController();
    final theme = ThemeController();

    return ThemeScope(
      controller: theme,
      child: PlayerScope(
        controller: player,
        child: SpotifyScope(
          session: spotify,
          child: Builder(
            builder: (context) {
              final themeCtrl = ThemeScope.of(context);

              return MaterialApp(
                debugShowCheckedModeBanner: false,

                // ✅ Dark mode control here
                themeMode: themeCtrl.mode,
                theme: ThemeData(
                  useMaterial3: true,
                  colorSchemeSeed: const Color.fromARGB(255, 78, 187, 211),
                  brightness: Brightness.light,
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorSchemeSeed: const Color.fromARGB(255, 52, 106, 222),
                  brightness: Brightness.dark,
                ),

                home: const AppShell(),
              );
            },
          ),
        ),
      ),
    );
  }
}
