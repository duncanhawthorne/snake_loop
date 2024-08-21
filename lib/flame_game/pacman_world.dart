import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/geometry.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import 'components/blocking_bar_layer.dart';
import 'components/ghost_layer.dart';
import 'components/pacman.dart';
import 'components/pacman_layer.dart';
import 'components/pellet_layer.dart';
import 'components/tutorial_layer.dart';
import 'components/wall_layer.dart';
import 'components/wrapper_no_events.dart';
import 'effects/remove_effects.dart';
import 'effects/rotate_effect.dart';
import 'pacman_game.dart';

/// The world is where you place all the components that should live inside of
/// the game, like the player, enemies, obstacles and points for example.
/// The world can be much bigger than what the camera is currently looking at,
/// but in this game all components that go outside of the size of the viewport
/// are removed, since the player can't interact with those anymore.
///
/// The [PacmanWorld] has two mixins added to it:
///  - The [DragCallbacks] that makes it possible to react to taps and drags
///  (or mouse clicks) on the world.
///  - The [HasGameReference] that gives the world access to a variable called
///  `game`, which is a reference to the game class that the world is attached
///  to.

final bool _iOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;

class PacmanWorld extends Forge2DWorld
    with
        //TapCallbacks,
        HasGameReference<PacmanGame>,
        //PointerMoveCallbacks,
        DragCallbacks {
  PacmanWorld({
    required this.level,
    required this.playerProgress,
    Random? random,
  });

  /// The properties of the current level.
  final GameLevel level;

  /// Used to see what the current progress of the player is and to update the
  /// progress if a level is finished.
  final PlayerProgress playerProgress;

  final noEventsWrapper = WrapperNoEvents();
  final pacmans = Pacmans();
  final ghosts = Ghosts();
  final pellets = PelletWrapper();
  final _walls = WallWrapper();
  final _tutorial = TutorialWrapper();
  final _blocking = BlockingBarWrapper();
  final List<WrapperNoEvents> wrappers = [];

  bool get gameWonOrLost =>
      pellets.pelletsRemainingNotifier.value <= 0 ||
      pacmans.numberOfDeathsNotifier.value >= level.maxAllowedDeaths;

  final Map<int, double?> _fingersLastDragAngle = {};

  bool doingLevelResetFlourish = false;
  bool _cameraRotatableOnPacmanDeathFlourish = true;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  void play(SfxType type) {
    const soundOn = true; //!(windows && !kIsWeb);
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void resetAfterGameWin() {
    game.audioController.stopSfx(SfxType.ghostsScared);
    play(SfxType.endMusic);
    ghosts.resetAfterGameWin();
  }

  static const bool _slideCharactersAfterPacmanDeath = true;

  void resetAfterPacmanDeath(Pacman dyingPacman) {
    _resetSlideAfterPacmanDeath(dyingPacman);
  }

  void _resetSlideAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    game.audioController.stopSfx(SfxType.ghostsScared);
    if (!gameWonOrLost) {
      if (_slideCharactersAfterPacmanDeath) {
        _cameraRotatableOnPacmanDeathFlourish = false;
        dyingPacman.resetSlideAfterDeath();
        ghosts.resetSlideAfterPacmanDeath();
        resetSlideAngle(game.camera.viewfinder,
            onComplete: _resetInstantAfterPacmanDeath);
      } else {
        _resetInstantAfterPacmanDeath();
      }
    } else {
      doingLevelResetFlourish = false;
    }
  }

  void _resetInstantAfterPacmanDeath() {
    // ignore: dead_code
    if (true || doingLevelResetFlourish) {
      // must test doingLevelResetFlourish
      // as could have been removed by reset during delay x 2
      // but this code is only run from resetSlide,
      // so if we have got here (accidentally) then resetSlide has run
      // and rotation will be wrong
      // so should clean up anyway
      pacmans.resetInstantAfterPacmanDeath();
      ghosts.resetInstantAfterPacmanDeath();
      _cameraAndTimersReset();
    }
  }

  void _cameraAndTimersReset() {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    removeEffects(game.camera.viewfinder);
    _setMazeAngle(0);
    _cameraRotatableOnPacmanDeathFlourish = true;
    doingLevelResetFlourish = false;
  }

  void reset({firstRun = false}) {
    _cameraAndTimersReset();

    if (!firstRun) {
      for (WrapperNoEvents wrapper in wrappers) {
        assert(wrapper.isLoaded);
        wrapper.reset();
      }
    }
  }

  void start() {
    play(SfxType.startMusic);
    for (WrapperNoEvents wrapper in wrappers) {
      wrapper.start();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(noEventsWrapper);
    wrappers.addAll([pacmans, ghosts, pellets, _walls, _tutorial, _blocking]);
    for (WrapperNoEvents wrapper in wrappers) {
      noEventsWrapper.add(wrapper);
    }
    reset(firstRun: true);
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_iOSWeb) {
      _fingersLastDragAngle[event.pointerId] = null;
    } else {
      _fingersLastDragAngle[event.pointerId] = atan2(
          event.canvasPosition.x - game.canvasSize.x / 2,
          event.canvasPosition.y - game.canvasSize.y / 2);
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    game.resume();
    double eventVectorLengthProportion =
        (event.canvasStartPosition - game.canvasSize / 2).length /
            (min(game.canvasSize.x, game.canvasSize.y) / 2);
    double fingerCurrentDragAngle = atan2(
        event.canvasStartPosition.x - game.canvasSize.x / 2,
        event.canvasStartPosition.y - game.canvasSize.y / 2);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      if (_fingersLastDragAngle[event.pointerId] != null) {
        double angleDelta = smallAngle(
            fingerCurrentDragAngle - _fingersLastDragAngle[event.pointerId]!);
        double spinMultiplier = 4 * min(1, eventVectorLengthProportion / 0.75);

        _tutorial.hide();
        _moveMazeAngleByDelta(angleDelta * spinMultiplier);
      }
      _fingersLastDragAngle[event.pointerId] = fingerCurrentDragAngle;
    }
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      _fingersLastDragAngle.remove(event.pointerId);
    }
  }

  void _moveMazeAngleByDelta(double angleDelta) {
    if (_cameraRotatableOnPacmanDeathFlourish && game.isGameLive) {
      _setMazeAngle(game.camera.viewfinder.angle + angleDelta);

      if (!doingLevelResetFlourish) {
        game.stopwatch.resume();
        ghosts.addSpawner();
        ghosts.sirenVolumeUpdatedTimer();
      }
    }
  }

  final _tmpGravity = Vector2.zero();
  static const double _gravityScale = 50 * (30 / flameGameZoom);
  void _setMazeAngle(double angle) {
    //using tmpGravity to avoid creating a new Vector2 on each update / frame
    //could instead directly do gravity = Vector2(calc, calc);
    _tmpGravity
      ..x = cos(angle + tau / 4) * _gravityScale
      ..y = sin(angle + tau / 4) * _gravityScale;
    gravity = _tmpGravity;
    game.camera.viewfinder.angle = angle;
  }
}
