import 'dart:async' as async;

import 'package:flame/components.dart';

import '../../utils/helper.dart';
import '../components/wrapper_no_events.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class GameInactivityMonitor extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  int _framesRendered = 0;

  async.Timer? _activityCheckTimer;

  void _pauseEngineIfNoActivity() {
    game.resumeEngine(); //for any catch up animation, if not already resumed
    _framesRendered = 0;
    _activityCheckTimer?.cancel(); // Kill any preexisting active loops
    // If all characters at starting position and nothing happening,
    // pause engine to save resources and avoid unnecessary animation
    // check every 10ms, but only pause if nothing happening and still at starting position
    // if something is happening, or not at starting position, then cancel timer and don't pause
    _activityCheckTimer = async.Timer.periodic(
      const Duration(milliseconds: 1000),
      (async.Timer timer) {
        if (game.paused) {
          //already paused, no further action required, just cancel timer
          timer.cancel();
        } else if (game.playState == PlayState.playbackMode) {
          //want to continue playback in playbackMode
          timer.cancel();
        } else if (game.lifecycle.stopwatch.isRunning()) {
          //some game activity has happened, no need to pause, just cancel timer
          timer.cancel();
        } else if (_framesRendered >= 60) {
          //everything loaded and rendered, and still no game activity
          logGlobal("inactive");
          game.pauseEngine();
          timer.cancel();
          if (_activityCheckTimer == timer) _activityCheckTimer = null;
        }
      },
    );
  }

  @override
  Future<void> reset() async {
    _pauseEngineIfNoActivity();
  }

  @override
  Future<void> start() async {
    _pauseEngineIfNoActivity();
  }

  @override
  void update(double dt) {
    _activityCheckTimer == null ? null : _framesRendered++;
    super.update(dt);
  }

  @override
  Future<void> onRemove() async {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = null;
  }
}
