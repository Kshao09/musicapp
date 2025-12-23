import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'state/player_controller.dart';
import 'state/player_scope.dart';
import 'state/spotify_scope.dart';
import 'state/spotify_session.dart';

import 'state/theme_controller.dart';
import 'state/theme_scope.dart';

import 'state/custom_playlists_controller.dart';
import 'state/custom_playlists_scope.dart';

const clientId = "2bceff485b9341d2b1d2fa89197b7d07";
const redirectUrl = "musicapp-login://callback";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final spotify = SpotifySession(clientId: clientId, redirectUrl: redirectUrl);
  final player = PlayerController();
  final theme = ThemeController();
  final customPlaylists = CustomPlaylistsController();

  await Future.wait([
    theme.load(),
    customPlaylists.load(),
  ]);

  runApp(
    MusicApp(
      spotify: spotify,
      player: player,
      theme: theme,
      customPlaylists: customPlaylists,
    ),
  );
}

class MusicApp extends StatelessWidget {
  final SpotifySession spotify;
  final PlayerController player;
  final ThemeController theme;
  final CustomPlaylistsController customPlaylists;

  const MusicApp({
    super.key,
    required this.spotify,
    required this.player,
    required this.theme,
    required this.customPlaylists,
  });

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: theme,
      child: PlayerScope(
        controller: player,
        child: SpotifyScope(
          session: spotify,
          child: CustomPlaylistsScope(
            controller: customPlaylists,
            child: Builder(
              builder: (context) {
                final themeCtrl = ThemeScope.of(context);

                return MaterialApp(
                  debugShowCheckedModeBanner: false,
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
      ),
    );
  }
}
