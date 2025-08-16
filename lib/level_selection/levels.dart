import 'dart:math';

import 'package:flutter/foundation.dart';

import '../flame_game/pacman_game.dart';

class Levels {
  static const int firstRealLevel = 1;
  static const int maxLevel = 15;
  static const int minLevel = 1;
  static const int levelToShowInstructions = defaultLevelNum;
  static const int playbackModeLevel = -4;
  static const int defaultLevelNum = firstRealLevel;

  static const List<int> _ghostSpawnTimerLengthPattern = <int>[5, 3, 2, 1];

  static const double _levelSpeedFactor =
      50 * (30 / flameGameZoom) * (kDebugMode ? 1 : 1);

  double _tutorialFactor(int levelNum) {
    return levelNum >= 1
        ? 1
        : levelNum == minLevel
        ? 0.75
        : 0.75; //not possible
  }

  GameLevel getLevel(int levelNum) {
    assert(
      levelNum <= maxLevel && levelNum >= minLevel ||
          levelNum == playbackModeLevel,
    );
    bool playbackMode = false;
    if (levelNum == playbackModeLevel) {
      levelNum = firstRealLevel;
      playbackMode = true;
    }
    final GameLevel result = (
      number: playbackMode ? playbackModeLevel : levelNum,
      maxAllowedDeaths: 1,
      superPelletsEnabled: levelNum <= 1 ? true : false,
      multipleSpawningGhosts: levelNum <= 2 ? false : true,
      ghostSpawnTimerLength: levelNum <= 2
          ? -1
          : _ghostSpawnTimerLengthPattern[(levelNum - 3) %
                _ghostSpawnTimerLengthPattern.length],
      homingGhosts: levelNum <= 2 + _ghostSpawnTimerLengthPattern.length
          ? false
          : true,
      isTutorial: levelNum <= 0,
      levelSpeed: _levelSpeedFactor * 0.25 * pow(1.1, levelNum).toDouble(),
      ghostScaredTimeFactor: _tutorialFactor(levelNum),
      spinSpeedFactor: _tutorialFactor(levelNum),
      numStartingGhosts: levelNum >= 0
          ? 3
          : levelNum == minLevel
          ? 3
          : (levelNum - 1) % 3 + 1, //not possible
      levelString: levelNum > 0
          ? "L$levelNum"
          : "Tutorial", //${levelNum - minLevel + 1}",
      infLives: levelNum <= 0 ? true : false,
    );
    return result;
  }
}

final Levels levels = Levels();

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts,
  int ghostSpawnTimerLength,
  bool homingGhosts,
  bool isTutorial,
  double levelSpeed,
  double ghostScaredTimeFactor,
  double spinSpeedFactor,
  int numStartingGhosts,
  String levelString,
  bool infLives,
});
