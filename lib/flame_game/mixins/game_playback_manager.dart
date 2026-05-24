import 'dart:core';

import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flame_forge2d/forge2d_game.dart';
import 'package:flutter/foundation.dart';

import '../../level_selection/levels.dart';
import '../../utils/helper.dart';
import '../../utils/stored_moves.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

mixin GamePlaybackManager on Forge2DGame<PacmanWorld> {
  late int _playbackModeCounter;
  bool playbackMode = false;

  // ignore: dead_code
  static const bool _recordMode = kDebugMode && false;
  final List<List<double>> _recordedMovesLive = <List<double>>[];

  void recordAngle(double angle) {
    if (_recordMode && !playbackMode) {
      _recordedMovesLive.add(<double>[
        ((this as PacmanGame).stopwatchMilliSeconds).toDouble(),
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
        (this as PacmanGame).framesRendered > 30) {
      // && isLive && overlays.isActive(GameScreen.startDialogKey)
      if (_playbackModeCounter == -1) {
        _playbackModeCounter++;
        (this as PacmanGame).startRegularItems();
      }
      while (!world.doingLevelResetFlourish &&
          _playbackModeCounter < storedMoves.length &&
          (this as PacmanGame).stopwatchMilliSeconds >
              storedMoves[_playbackModeCounter][0]) {
        world.dragManager.setMazeAngle(storedMoves[_playbackModeCounter][1]);
        _playbackModeCounter++;
      }
      if (!world.doingLevelResetFlourish &&
          (this as PacmanGame).stopwatchMilliSeconds > 20000) {
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
}
