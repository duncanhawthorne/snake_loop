import 'dart:async';

import 'package:flame/components.dart';

import '../components/wrapper_no_events.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class DialogManager extends WrapperNoEvents
    with HasWorldReference<PacmanWorld> {
  late final PacmanGame game;

  void clean() {
    game.overlays
      ..remove(GameScreen.startDialogKey)
      ..remove(GameScreen.loseDialogKey)
      ..remove(GameScreen.wonDialogKey)
      ..remove(GameScreen.tutorialDialogKey)
      ..remove(GameScreen.resetDialogKey)
      ..remove(GameScreen.debugDialogKey);
  }

  void toggle(String overlayKey) {
    if (game.overlays.activeOverlays.contains(overlayKey)) {
      game.overlays.remove(overlayKey);
    } else {
      clean();
      game.overlays.add(overlayKey);
    }
  }

  @override
  Future<void> onRemove() async {
    clean();
  }
}
