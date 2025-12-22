import "package:flutter/material.dart";
import "app/app.dart";
import "state/player_scope.dart";
import "state/player_controller.dart";

void main() {
  final controller = PlayerController();
  runApp(PlayerScope(controller: controller, child: MusicApp()));
}