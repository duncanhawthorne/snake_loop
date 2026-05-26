import 'dart:core';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../level_selection/levels.dart';
import '../../utils/helper.dart';
import '../../utils/stored_moves.dart';
import '../components/wrapper_no_events.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class GamePlaybackManager extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  late int _playbackModeCounter;
  bool playbackMode = false;

  // ignore: dead_code
  static const bool _recordMode = kDebugMode && false;
  final List<List<double>> _recordedMovesLive = <List<double>>[];

  void recordAngle(double angle) {
    if (_recordMode && !playbackMode) {
      _recordedMovesLive.add(<double>[
        ((this as PacmanGame).session.stopwatchMilliSeconds).toDouble(),
        angle,
      ]);
      if (_recordedMovesLive.length % 100 == 0) {
        logGlobal(_recordedMovesLive);
      }
    }
  }

  void playbackAngles() {
    if (playbackMode &&
        (this as PacmanGame).isLive &&
        (this as PacmanGame).world.activityMonitor.framesRendered > 30) {
      // && isLive && overlays.isActive(GameScreen.startDialogKey)
      if (_playbackModeCounter == -1) {
        _playbackModeCounter++;
        (this as PacmanGame).lifecycle.startRegularItems();
      }
      while (!world.deathManager.doingLevelResetFlourish &&
          _playbackModeCounter < storedMoves.length &&
          (this as PacmanGame).session.stopwatchMilliSeconds >
              storedMoves[_playbackModeCounter][0]) {
        world.dragManager.setMazeAngle(storedMoves[_playbackModeCounter][1]);
        _playbackModeCounter++;
      }
      if (!world.deathManager.doingLevelResetFlourish &&
          (this as PacmanGame).session.stopwatchMilliSeconds > 20000) {
        (this as PacmanGame).reset(); //if stuck, reset
      }
    }
  }

  void resetPlayback(GameLevel level) {
    //audioController.soLoudReset();
    _playbackModeCounter = -1;
    playbackMode = !_recordMode && level.number == Levels.playbackModeLevel;
    _recordedMovesLive.clear();
  }

  @override
  Future<void> reset() async {
    resetPlayback(game.level);
  }

  @override
  void start() {}

  @override
  void update(double dt) {
    playbackAngles();
    super.update(dt);
  }
}
