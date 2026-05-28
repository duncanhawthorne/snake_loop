import 'dart:core';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../level_selection/levels.dart';
import '../../utils/helper.dart';
import '../../utils/stored_moves.dart';
import '../components/wrapper_no_events.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class Playback extends WrapperNoEvents with HasWorldReference<PacmanWorld> {
  late final PacmanGame game;

  int _counter = 0;
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
    if (!(recordMode && !(game.playState == PlayState.playbackMode))) return;
    _recordedMovesLive.add(<double>[
      (game.session.stopwatchMilliSeconds).toDouble(),
      angle,
    ]);
    if (_recordedMovesLive.length % 100 == 0) {
      logGlobal(_recordedMovesLive);
    }
  }

  void _playbackAngles() {
    if (!(game.playState == PlayState.playbackMode && game.isLive)) return;
    final int stopwatch = game.session.stopwatchMilliSeconds;
    if (stopwatch > 20000) {
      game.reset(); //if stuck, reset
      return;
    }
    while (_counter + 1 < storedMoves.length &&
        storedMoves[_counter + 1][0] < stopwatch) {
      _counter++;
    }
    world.dragManager.setMazeAngle(storedMoves[_counter][1]);
  }

  void resetPlayback() {
    _counter = 0;
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
    _playbackAngles();
    super.update(dt);
  }
}
