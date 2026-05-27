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
    with HasWorldReference<PacmanWorld> {
  late final PacmanGame game;

  int _playbackModeCounter = -1;
  bool _playbackModeEverDismissed = false;

  static const bool recordMode = kDebugMode && false;
  final List<List<double>> _recordedMovesLive = <List<double>>[];

  void enable() {
    _playbackModeEverDismissed = false;
  }

  void disable() {
    _playbackModeEverDismissed = true;
  }

  bool isPlaybackAppropriate() {
    return !_playbackModeEverDismissed & !recordMode &&
        game.level.number == Levels.playbackModeLevel;
  }

  void recordAngle(double angle) {
    if (recordMode && !(game.playState == PlayState.playbackMode)) {
      _recordedMovesLive.add(<double>[
        (game.session.stopwatchMilliSeconds).toDouble(),
        angle,
      ]);
      if (_recordedMovesLive.length % 100 == 0) {
        logGlobal(_recordedMovesLive);
      }
    }
  }

  void playbackAngles() {
    if ((game.playState == PlayState.playbackMode) &&
        game.isLive &&
        game.world.inactivityMonitor.framesRendered > 30) {
      // && isLive && overlays.isActive(GameScreen.startDialogKey)
      if (_playbackModeCounter == -1) {
        _playbackModeCounter++;
        game.lifecycle.startRegularItems();
      }
      while (!world.deathManager.doingLevelResetFlourish &&
          _playbackModeCounter < storedMoves.length &&
          game.session.stopwatchMilliSeconds >
              storedMoves[_playbackModeCounter][0]) {
        world.dragManager.setMazeAngle(storedMoves[_playbackModeCounter][1]);
        _playbackModeCounter++;
      }
      if (!world.deathManager.doingLevelResetFlourish &&
          game.session.stopwatchMilliSeconds > 20000) {
        game.reset(); //if stuck, reset
      }
    }
  }

  void resetPlayback() {
    //audioController.soLoudReset();
    _playbackModeCounter = -1;
    _recordedMovesLive.clear();
  }

  @override
  Future<void> reset() async {
    resetPlayback();
  }

  @override
  void start() {}

  @override
  void update(double dt) {
    playbackAngles();
    super.update(dt);
  }
}
