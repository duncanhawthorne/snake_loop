import 'dart:core';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../../firebase/firebase_saves.dart';
import '../../utils/string_helper.dart';
import '../components/wrapper_no_events.dart';
import '../game_screen.dart';
import '../maze/maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class GameSession extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  String _userString = "";

  static const int _deathPenaltyMillis = 5000;

  int get stopwatchMilliSeconds =>
      (game.lifecycle.stopwatch.current * 1000).toInt() +
      (game.level.isTutorial
          ? 0
          : min(game.level.maxAllowedDeaths - 1, numberOfDeathsNotifier.value) *
                _deathPenaltyMillis);

  bool get isWonOrLost =>
      ((!kDebugMode || world.pellets.isMounted) &&
          world.pellets.pelletsRemainingNotifier.value <= 0) ||
      numberOfDeathsNotifier.value >= game.level.maxAllowedDeaths;

  VoidCallback? _deathListenerRef;
  VoidCallback? _pelletListenerRef;

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);

  Map<String, Object> _getCurrentGameState() {
    final Map<String, Object> gameStateTmp = <String, Object>{};
    gameStateTmp["userString"] = _userString;
    gameStateTmp["levelNum"] = game.level.number;
    gameStateTmp["levelCompleteTime"] = stopwatchMilliSeconds;
    gameStateTmp["dateTime"] = DateTime.now().millisecondsSinceEpoch;
    gameStateTmp["mazeId"] = maze.mazeId;
    return gameStateTmp;
  }

  void _winOrLoseGameListener() {
    assert(
      !game.lifecycle.stopwatchStarted,
    ); //so no instant trigger of listeners
    _deathListenerRef = () {
      if (numberOfDeathsNotifier.value >= game.level.maxAllowedDeaths &&
          game.lifecycle.stopwatchStarted &&
          !game.playback.playbackMode) {
        assert(!isRemoving);
        assert(game.session.isWonOrLost);
        game.lifecycle.stopRegularItems();
        _handleLoseGame();
      }
    };
    _pelletListenerRef = () {
      if (world.pellets.pelletsRemainingNotifier.value <= 0 &&
          game.lifecycle.stopwatchStarted &&
          !game.playback.playbackMode) {
        assert(!isRemoving);
        assert(game.session.isWonOrLost);
        game.lifecycle.stopRegularItems();
        _handleWinGame();
      }
    };
    numberOfDeathsNotifier.addListener(_deathListenerRef!);
    world.pellets.pelletsRemainingNotifier.addListener(_pelletListenerRef!);
  }

  void _handleWinGame() {
    assert(!isRemoving);
    assert(game.session.isWonOrLost);
    assert(!game.lifecycle.stopwatch.isRunning());
    assert(game.lifecycle.stopwatchStarted);
    if (world.pellets.pelletsRemainingNotifier.value <= 0) {
      game.play(SfxType.endMusic);
      world.ghosts.resetAfterGameWin();
      const int minRecordableWinTimeMillis = 10 * 1000;
      if (game.session.stopwatchMilliSeconds > minRecordableWinTimeMillis &&
          !game.level.isTutorial) {
        fBase.firebasePushSingleScore(_userString, _getCurrentGameState());
      }
      game.playerProgress.saveLevelComplete(_getCurrentGameState());
      game.overlayManager.cleanDialogs();
      game.overlays.add(GameScreen.wonDialogKey);
    }
  }

  void _handleLoseGame() {
    assert(!isRemoving);
    assert(game.session.isWonOrLost);
    assert(game.lifecycle.stopwatchStarted);
    game.audioController.stopAllSounds();
    game.overlayManager.cleanDialogs();
    game.overlays.add(GameScreen.loseDialogKey);
  }

  @override
  Future<void> reset() async {
    _userString = getRandomString(game.random, 15);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    _winOrLoseGameListener(); //isn't disposed so run once, not on start()
  }

  @override
  Future<void> onRemove() async {
    if (_deathListenerRef != null) {
      numberOfDeathsNotifier.removeListener(_deathListenerRef!);
    }
    if (_pelletListenerRef != null) {
      world.pellets.pelletsRemainingNotifier.removeListener(
        _pelletListenerRef!,
      );
    }
    numberOfDeathsNotifier.dispose();
    super.onRemove();
  }
}
