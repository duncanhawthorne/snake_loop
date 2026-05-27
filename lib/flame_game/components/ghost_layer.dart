import 'dart:async';

import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../effects/remove_effects.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'ghost_siren.dart';
import 'sprite_character.dart';
import 'wrapper_no_events.dart';

const int _kGhostScaredTimeMillis = 6000;

class Ghosts extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = 1;

  final List<Ghost> ghostList = <Ghost>[];

  CharacterState current = CharacterState.normal;
  Timer _ghostsScaredTimer = Timer(0); //length set in reset
  SpawnComponent? _ghostSpawner;
  final GhostSiren ghostSiren = GhostSiren();

  bool get ghostsLoaded => ghostList.isNotEmpty && ghostList[0].isLoaded;

  void _addThreeGhosts() {
    assert(ghostList.isEmpty);
    final List<int> positions = game.level.numStartingGhosts == 3
        ? <int>[0, 1, 2]
        : game.level.numStartingGhosts == 2
        ? <int>[0, 2]
        : <int>[1];
    for (int i = 0; i < game.level.numStartingGhosts; i++) {
      add(Ghost(ghostID: positions[i]));
    }
  }

  void scareGhosts() {
    if (!isMounted) {
      return;
    }
    current = CharacterState.scared;
    if (!game.session.isWonOrLost) {
      game.play(SfxType.ghostsScared);
      for (final Ghost ghost in ghostList) {
        ghost.setScared();
      }
      _ghostsScaredTimer.start();
    }
  }

  void addSpawner() {
    if (!isMounted) {
      return; //else cant use game references
    }
    assert(!game.session.isWonOrLost); //test before call, else test here
    if (game.level.multipleSpawningGhosts) {
      _ghostSpawner ??= SpawnComponent(
        factory: (int i) =>
            Ghost(ghostID: <int>[3, 4, 5][game.random.nextInt(3)]),
        selfPositioning: true,
        period: game.level.ghostSpawnTimerLength.toDouble(),
      );
      if (!_ghostSpawner!.isMounted) {
        add(_ghostSpawner!);
      }
    }
  }

  void removeSpawner() {
    if (!isMounted) {
      return; //else cant use game references
    }
    _ghostSpawner?.removeFromParent();
    _ghostSpawner = null; //FIXME shouldn't be necessary
    _ghostSpawner?.timer.reset(); //so next spawn based on time of reset
    game.lifecycle.noteThatSomeRegularItemHasStopped();
  }

  void _removeAllGhosts() {
    //create a new list toList so can iterate and remove simultaneously
    for (final Ghost ghost in ghostList.toList()) {
      ghost.removeFromParent();
    }
    removeSpawner();
  }

  void disconnectGhostsFromBalls() {
    for (final Ghost ghost in ghostList) {
      removeEffects(ghost);
      ghost.setPhysicsState(PhysicsState.none); //sync
    }
  }

  void startRegularItems() {
    addSpawner();
    ghostSiren.startSirenVolumeUpdaterTimer();
  }

  void stopRegularItems() {
    removeSpawner();
    ghostSiren.cancelSirenVolumeUpdaterTimer();
  }

  void resetAfterGameWin() {
    game.audioController.stopSound(SfxType.ghostsScared);
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    _removeAllGhosts();
  }

  void resetSlideAfterPacmanDeath() {
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    for (final Ghost ghost in ghostList) {
      ghost.resetSlideAfterPacmanDeath();
    }
  }

  void resetInstantAfterPacmanDeath() {
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    if (game.level.multipleSpawningGhosts) {
      _removeAllGhosts();
      _addThreeGhosts();
    } else {
      for (final Ghost ghost in ghostList) {
        ghost.resetInstantAfterPacmanDeath();
      }
      //no spawner to remove
    }
  }

  static const double _scaredToScaredIshThreshold = 2 / 3;

  void _stateSequence(double dt) {
    _ghostsScaredTimer.update(dt);
    if (current == CharacterState.scared) {
      if (_ghostsScaredTimer.current >
          _scaredToScaredIshThreshold * _ghostsScaredTimer.limit) {
        current = CharacterState.scaredIsh;
        for (final Ghost ghost in ghostList) {
          ghost.setScaredToScaredIsh();
        }
      }
    }
    if (current == CharacterState.scaredIsh) {
      if (_ghostsScaredTimer.finished) {
        current = CharacterState.normal;
        for (final Ghost ghost in ghostList) {
          ghost.setScaredIshToNormal();
        }
        _ghostsScaredTimer.pause(); //makes update function for timer free
        game.audioController.stopSound(SfxType.ghostsScared);
      }
    }
  }

  @override
  Future<void> reset({bool mazeResize = false}) async {
    unawaited(game.audioController.stopSound(SfxType.ghostsScared));
    ghostSiren.cancelSirenVolumeUpdaterTimer();
    current = CharacterState.normal;
    _ghostsScaredTimer.pause(); //makes update function for timer free
    _removeAllGhosts();
    _ghostSpawner = null; //so will reflect new level parameters
    _ghostsScaredTimer = Timer(
      _kGhostScaredTimeMillis / game.level.ghostScaredTimeFactor / 1000,
    );
    _addThreeGhosts();
  }

  @override
  void update(double dt) {
    _stateSequence(dt);
    super.update(dt);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(ghostSiren);
    await reset();
  }
}
