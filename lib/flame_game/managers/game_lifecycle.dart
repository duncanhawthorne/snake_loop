import 'dart:ui';

import 'package:flame/components.dart';

import '../components/wrapper_no_events.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class GameLifecycle extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  VoidCallback? _lifecycleListenerRef;
  bool _regularItemsStarted = false;

  bool _stopwatchStarted = false;

  bool get stopwatchStarted => _stopwatchStarted;
  final Timer stopwatch = Timer(double.infinity);

  void noteThatSomeRegularItemHasStopped() {
    //so that will restart later
    _regularItemsStarted = false;
  }

  void pauseGame() {
    game
      ..pause() //timeScale = 0;
      ..pauseEngine();
    noteThatSomeRegularItemHasStopped();
    //stopwatch.pause(); //shouldn't be necessary given timeScale = 0
  }

  void resumeGame() {
    if (game.paused) {
      noteThatSomeRegularItemHasStopped();
      game.audioController.workaroundiOSSafariAudioOnUserInteraction();
      game
        ..resume() //timeScale = 1.0;
        ..resumeEngine();
    }
  }

  void startRegularItems() {
    if (!_regularItemsStarted) {
      game.audioController.workaroundiOSSafariAudioOnUserInteraction();
      _regularItemsStarted = true;
      _stopwatchStarted = true; //once per reset
      stopwatch.resume();
      world.ghosts.startRegularItems();
    }
  }

  void stopRegularItems() {
    noteThatSomeRegularItemHasStopped();
    stopwatch.pause();
    world.ghosts.stopRegularItems();
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
    _stopwatchStarted = false;
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
