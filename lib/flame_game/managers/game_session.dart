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

  bool get isWon => world.pellets.winState;

  bool get isLost =>
      numberOfDeathsNotifier.value >= game.level.maxAllowedDeaths;

  bool get isWonOrLost => isWon || isLost;

  VoidCallback? _deathsListenerRef;
  VoidCallback? _itemsListenerRef;

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);
  late final ValueNotifier<int> itemsRemainingNotifier =
      world.pellets.pelletsRemainingNotifier;

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
    assert(!game.lifecycle.stopwatchStarted); //so no instant trigger
    _deathsListenerRef = () {
      if (isLost &&
          game.lifecycle.stopwatchStarted &&
          game.playState != PlayState.playbackMode) {
        _handleLoseGame();
      }
    };
    _itemsListenerRef = () {
      if (isWon &&
          game.lifecycle.stopwatchStarted &&
          game.playState != PlayState.playbackMode) {
        _handleWinGame();
      }
    };
    numberOfDeathsNotifier.addListener(_deathsListenerRef!);
    itemsRemainingNotifier.addListener(_itemsListenerRef!);
  }

  void _handleWinGame() {
    assert(!isRemoving);
    assert(isWonOrLost);
    assert(!game.lifecycle.stopwatch.isRunning());
    assert(game.lifecycle.stopwatchStarted);
    assert(!(game.playState == PlayState.playbackMode));
    game.lifecycle.stopRegularItems();
    game.play(SfxType.endMusic);
    world.ghosts.resetAfterGameWin();
    const int minRecordableWinTimeMillis = 10 * 1000;
    if (stopwatchMilliSeconds > minRecordableWinTimeMillis &&
        !game.level.isTutorial) {
      fBase.firebasePushSingleScore(_userString, _getCurrentGameState());
    }
    game.playerProgress.saveLevelComplete(_getCurrentGameState());
    game.dialogs.clean();
    game.overlays.add(GameScreen.wonDialogKey);
  }

  void _handleLoseGame() {
    assert(!isRemoving);
    assert(isWonOrLost);
    assert(game.lifecycle.stopwatchStarted);
    game.lifecycle.stopRegularItems();
    game.audioController.stopAllSounds();
    game.dialogs.clean();
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
    if (_deathsListenerRef != null) {
      numberOfDeathsNotifier.removeListener(_deathsListenerRef!);
    }
    if (_itemsListenerRef != null) {
      itemsRemainingNotifier.removeListener(_itemsListenerRef!);
    }
    itemsRemainingNotifier.dispose();
    numberOfDeathsNotifier.dispose();
    super.onRemove();
  }
}
