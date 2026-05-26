import 'dart:async';

import 'package:flame/components.dart';

import '../components/wrapper_no_events.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class GameOverlayManager extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  bool fullyLoaded = false;

  Future<void> ensureLoaded() async {
    if (!fullyLoaded) {
      await mounted;
      await game.playback.mounted;
      fullyLoaded = true;
    }
  }

  Future<void> cleanDialogs() async {
    await ensureLoaded();
    game.overlays
      ..remove(GameScreen.startDialogKey)
      ..remove(GameScreen.loseDialogKey)
      ..remove(GameScreen.wonDialogKey)
      ..remove(GameScreen.tutorialDialogKey)
      ..remove(GameScreen.resetDialogKey)
      ..remove(GameScreen.debugDialogKey);
  }

  Future<void> toggleOverlay(String overlayKey) async {
    await ensureLoaded();
    if (game.overlays.activeOverlays.contains(overlayKey)) {
      game.overlays.remove(overlayKey);
    } else {
      await cleanDialogs();
      game.overlays.add(overlayKey);
    }
  }

  Future<void> customReset({bool showStartDialog = false}) async {
    await ensureLoaded();
    await cleanDialogs();
    if (showStartDialog) {
      game.playback.playbackMode
          ? game.overlays.add(GameScreen.beginDialogKey)
          : game.overlays.add(GameScreen.startDialogKey);
    }
  }

  @override
  Future<void> reset({bool showStartDialog = false}) async {}

  @override
  void start() {}

  @override
  Future<void> onRemove() async {
    await cleanDialogs();
  }
}
