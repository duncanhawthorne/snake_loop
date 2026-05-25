import 'dart:async' as async;

import 'package:flame/components.dart';

import '../components/wrapper_no_events.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class GameActivityMonitor extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  int framesRendered = 0;

  async.Timer? _activityCheckTimer;

  void _pauseEngineIfNoActivity() {
    game.resumeEngine(); //for any catch up animation, if not already resumed
    framesRendered = 0;
    _activityCheckTimer?.cancel(); // Kill any preexisting active loops
    // If all characters at starting position and nothing happening,
    // pause engine to save resources and avoid unnecessary animation
    // check every 10ms, but only pause if nothing happening and still at starting position
    // if something is happening, or not at starting position, then cancel timer and don't pause
    _activityCheckTimer = async.Timer.periodic(
      const Duration(milliseconds: 10),
      (async.Timer timer) {
        if (game.paused) {
          //already paused, no further action required, just cancel timer
          timer.cancel();
        } else if (game.playbackMode) {
          //want to continue playback in playbackMode
          timer.cancel();
        } else if (game.stopwatch.isRunning()) {
          //some game activity has happened, no need to pause, just cancel timer
          timer.cancel();
        } else if (!world.isMounted || !world.ghosts.ghostsLoaded) {
          //core components haven't loaded yet, so wait before start frame count
          framesRendered = 0;
        } else if (framesRendered <= 5) {
          //core components loaded, but not yet had 5 good safety frame
        } else {
          //everything loaded and rendered, and still no game activity
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
    framesRendered++;
    super.update(dt);
  }

  @override
  Future<void> onRemove() async {
    _activityCheckTimer?.cancel();
    _activityCheckTimer = null;
  }
}
