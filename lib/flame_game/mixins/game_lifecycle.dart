import 'dart:ui';

import 'package:flame/components.dart';

import '../components/wrapper_no_events.dart';
import '../game_screen.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class GameLifecycle extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  VoidCallback? _lifecycleListenerRef;
  bool regularItemsStarted = false;

  bool stopwatchStarted = false;
  final Timer stopwatch = Timer(double.infinity);

  bool get openingScreenCleared =>
      !(!stopwatchStarted && game.overlays.isActive(GameScreen.startDialogKey));

  void pauseGame() {
    game
      ..pause() //timeScale = 0;
      ..pauseEngine();
    regularItemsStarted = false; //so restart things next time
    //stopwatch.pause(); //shouldn't be necessary given timeScale = 0
  }

  void resumeGame() {
    if (game.paused) {
      regularItemsStarted = false; //so restart things next time
      game.audioController.workaroundiOSSafariAudioOnUserInteraction();
      game
        ..resume() //timeScale = 1.0;
        ..resumeEngine();
    }
  }

  void startRegularItems() {
    if (!regularItemsStarted) {
      game.audioController.workaroundiOSSafariAudioOnUserInteraction();
      regularItemsStarted = true;
      game.lifecycle.stopwatchStarted = true; //once per reset
      game.lifecycle.stopwatch.resume();
      world.ghosts
        ..addSpawner()
        ..ghostSiren.startSirenVolumeUpdaterTimer();
    }
  }

  void stopRegularItems() {
    regularItemsStarted = false;
    game.lifecycle.stopwatch.pause();
    world.ghosts
      ..removeSpawner()
      ..ghostSiren.cancelSirenVolumeUpdaterTimer();
  }

  void _lifecycleChangeListener() {
    _lifecycleListenerRef = () {
      if (game.appLifecycleStateNotifier.value == AppLifecycleState.hidden) {
        assert(!isRemoving);
        pauseGame();
      }
    };
    game.appLifecycleStateNotifier.addListener(_lifecycleListenerRef!);
  }

  @override
  Future<void> reset() async {
    stopRegularItems(); //duplicates other items, belt and braces only
    stopwatch
      ..pause()
      ..reset();
    stopwatchStarted = false;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _lifecycleChangeListener(); //isn't disposed so run once, not on start()
  }

  @override
  Future<void> onRemove() async {
    if (_lifecycleListenerRef != null) {
      game.appLifecycleStateNotifier.removeListener(_lifecycleListenerRef!);
    }
    super.onRemove();
  }

  @override
  void update(double dt) {
    stopwatch.update(dt * game.timeScale); //stops stopwatch when timeScale = 0
    super.update(dt);
  }
}
