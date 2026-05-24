import 'dart:async';
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import 'components/blocking_bar_layer.dart';
import 'components/ghost_layer.dart';
import 'components/lap_angle.dart';
import 'components/pacman.dart';
import 'components/pacman_layer.dart';
import 'components/pellet_layer.dart';
import 'components/wall_dynamic_layer.dart';
import 'components/wall_layer.dart';
import 'components/wrapper_no_events.dart';
import 'mixins/world_drag_rotation_manager.dart';
import 'pacman_game.dart';

/// The world is where you place all the components that should live inside of
/// the game, like the player, enemies, obstacles and points for example.
///
/// The [PacmanWorld] has two mixins added to it:
///  - The [DragCallbacks] that makes it possible to react to taps and drags
///  (or mouse clicks) on the world.
///  - The [HasGameReference] that gives the world access to a variable called
///  `game`, which is a reference to the game class that the world is attached
///  to.

class PacmanWorld extends Forge2DWorld
    with HasGameReference<PacmanGame>, DragCallbacks {
  PacmanWorld._();

  factory PacmanWorld() {
    assert(_instance == null);
    _instance ??= PacmanWorld._();
    return _instance!;
  }

  ///ensures singleton [PacmanWorld]
  static PacmanWorld? _instance;

  final WrapperNoEvents noEventsWrapper = WrapperNoEvents();
  final Pacmans pacmans = Pacmans();
  final Ghosts ghosts = Ghosts();
  final PelletWrapper pellets = PelletWrapper();
  final WallWrapper _walls = WallWrapper();
  final BlockingBarWrapper _blocking = BlockingBarWrapper();
  final MovingWallWrapper _movingWalls = MovingWallWrapper();
  final List<WrapperNoEvents> wrappers = <WrapperNoEvents>[];

  bool doingLevelResetFlourish = false;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  void play(SfxType type) {
    const bool soundOn = true; //!(windows && !kIsWeb);
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void resetAfterGameWin() {
    game.audioController.stopSound(SfxType.ghostsScared);
    play(SfxType.endMusic);
    ghosts.resetAfterGameWin();
  }

  static const bool _slideCharactersAfterPacmanDeath = true;

  void resetAfterPacmanDeath(Pacman dyingPacman) {
    _resetSlideAfterPacmanDeath(dyingPacman);
  }

  void _resetSlideAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    game.audioController.stopSound(SfxType.ghostsScared);
    if (!game.isWonOrLost) {
      if (_slideCharactersAfterPacmanDeath) {
        dragManager.flourishReset(_resetInstantAfterPacmanDeath);
        dyingPacman.resetSlideAfterDeath();
        ghosts.resetSlideAfterPacmanDeath();
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
      // originally thought must test doingLevelResetFlourish
      // as could have been removed by reset during delay x 2
      // but this code is only run from resetSlide,
      // so if we have got here (accidentally) then resetSlide has run
      // and rotation will be wrong
      // so should clean up anyway
      if (game.level.infLives) {
        game.numberOfDeathsNotifier.value = 0;
        pacmans.pacmanDyingNotifier.value = 0;
      }
      pacmans.resetInstantAfterPacmanDeath();
      ghosts.resetInstantAfterPacmanDeath();
      _cameraAndTimersReset();
      if (game.playbackMode) {
        game.reset();
      } else {
        game.pauseEngineIfNoActivity();
      }
    }
  }

  void _cameraAndTimersReset() {
    dragManager.reset();
    doingLevelResetFlourish = false;
  }

  void reset({bool firstRun = false}) {
    _cameraAndTimersReset();
    game.audioController.stopSound(SfxType.ghostsScared);

    if (!firstRun) {
      for (final WrapperNoEvents wrapper in wrappers) {
        assert(wrapper.isLoaded, wrapper);
        wrapper.reset();
      }
    }
  }

  void start() {
    play(SfxType.startMusic);
    for (final WrapperNoEvents wrapper in wrappers) {
      wrapper.start();
    }
  }

  static const bool enableMovingWalls = kDebugMode && false;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(noEventsWrapper);
    wrappers.addAll(<WrapperNoEvents>[
      pacmans,
      ghosts,
      if (!enableRotationRaceMode) pellets,
      _walls,
      _blocking,
      if (enableMovingWalls) _movingWalls,
    ]);
    for (final WrapperNoEvents wrapper in wrappers) {
      noEventsWrapper.add(wrapper);
    }
    reset(firstRun: true);
  }

  @override
  void onRemove() {
    dragManager.clear();
    wrappers.clear();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    dragManager.canvasRadius = min(game.canvasSize.x, game.canvasSize.y) / 2;
  }

  late final WorldDragRotationManager dragManager = WorldDragRotationManager(
    game: game,
    world: this,
  );
  final Vector2 gravitySign = Vector2.zero();

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    dragManager.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    dragManager.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    dragManager.onDragEnd(event);
  }
}
