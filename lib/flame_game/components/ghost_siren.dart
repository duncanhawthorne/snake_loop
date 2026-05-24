import 'dart:async' as async;

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../../utils/helper.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'ghost.dart';
import 'ghost_layer.dart';
import 'sprite_character.dart';
import 'wrapper_no_events.dart';

class GhostSiren extends WrapperNoEvents
    with HasGameReference<PacmanGame>, HasWorldReference<PacmanWorld> {
  late final Ghosts ghosts = world.ghosts;
  late final List<Ghost> ghostList = ghosts.ghostList;

  async.Timer? _sirenTimer;

  void _tidyStrayGhosts() {
    const bool testStrayGhosts = false;
    if (!testStrayGhosts) {
      return;
    }
    // ignore: dead_code
    if (kDebugMode && !game.level.multipleSpawningGhosts) {
      if (ghostList.length > game.level.numStartingGhosts) {
        //create a new list toList so can iterate and remove simultaneously
        final List<Ghost> tmpList = ghostList.toList();
        for (Ghost ghost in tmpList) {
          if (!ghost.isMounted) {
            logGlobal("tidy stray ghost 1"); //shouldn't happen
            ghost.removeFromParent();
          }
        }
      }
      if (ghosts.children.whereType<Ghost>().length != ghostList.length) {
        //create a new list toList so can iterate and remove simultaneously
        final List<Component> tmpList = ghosts.children
            .whereType<Ghost>()
            .toList();
        for (Component child in tmpList) {
          if (!ghostList.contains(child)) {
            logGlobal("tidy stray ghost 2"); //shouldn't happen
            child.removeFromParent();
          }
        }
      }
    }
  }

  double _averageGhostSpeed() {
    assert(game.isLive); //test before call, else test here
    assert(game.openingScreenCleared);
    assert(
      !world.pacmans.isMounted || world.pacmans.anyAlivePacman,
    ); //test before call, else test here
    assert(!game.isWonOrLost); //test before call, else test here
    _tidyStrayGhosts();
    if (ghostList.isEmpty) {
      return 0;
    } else {
      return ghostList
              .map(
                (Ghost ghost) =>
                    ghost.current == CharacterState.normal ? ghost.speed : 0.0,
              ) //scared ghosts give zero which silences ghostsRoamingSiren
              .reduce((double value, double element) => value + element) /
          ghostList.length;
    }
  }

  async.Future<void> startSirenVolumeUpdaterTimer() async {
    final bool sirenEnabled = game.audioController.canDoVariableVolume;
    if (sirenEnabled) {
      if (!ghosts.isMounted) {
        return;
      }
      assert(!game.isWonOrLost); //test before call, else test here
      assert(game.isLive); //test before call, else test here
      assert(game.openingScreenCleared);
      _sirenTimer ??= async.Timer.periodic(const Duration(milliseconds: 250), (
        async.Timer timer,
      ) {
        assert(!game.isWonOrLost); //timer cancelled already here
        assert(
          !world.pacmans.isMounted || world.pacmans.anyAlivePacman,
        ); //timer cancelled already here
        assert(
          !world.deathManager.doingLevelResetFlourish,
        ); //timer cancelled already here
        assert(game.openingScreenCleared);
        if (game.isLive) {
          game.audioController.setSirenVolume(
            _averageGhostSpeed() * flameGameZoom / 30,
            gradual: true,
          );
        } else {
          cancelSirenVolumeUpdaterTimer();
        }
      });
    }
  }

  void cancelSirenVolumeUpdaterTimer() {
    if (_sirenTimer != null) {
      game.audioController.setSirenVolume(0);
      _sirenTimer!.cancel();
      _sirenTimer = null;
      game.regularItemsStarted = false; //so that will restart later
    }
  }
}
