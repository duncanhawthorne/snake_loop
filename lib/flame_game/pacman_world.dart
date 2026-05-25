import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import 'components/pellet_layer.dart';
import 'components/snake_wrapper.dart';
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
    with HasGameReference<PacmanGame>, DragCallbacks, TapCallbacks {
  PacmanWorld._();

  factory PacmanWorld() {
    assert(_instance == null);
    _instance ??= PacmanWorld._();
    return _instance!;
  }

  ///ensures singleton [PacmanWorld]
  static PacmanWorld? _instance;

  static const bool enableMovingWalls = kDebugMode && false;
  final Vector2 gravitySign = Vector2.zero();

  late final WorldDragRotationManager dragManager = WorldDragRotationManager(
    game: game,
    world: this,
  );

  final WrapperNoEvents noEventsWrapper = WrapperNoEvents();
  final PelletWrapper pellets = PelletWrapper();
  final WallWrapper _walls = WallWrapper();
  final List<WrapperNoEvents> wrappers = <WrapperNoEvents>[];

  void play(SfxType type) {
    const bool soundOn = true; //!(windows && !kIsWeb);
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void resetAfterGameWin() {
    game.audioController.stopSound(SfxType.ghostsScared);
    play(SfxType.endMusic);
  }

  void reset({bool firstRun = false}) {
    dragManager.reset();
    game.audioController.stopSound(SfxType.ghostsScared);

    if (!firstRun) {
      for (final WrapperNoEvents wrapper in wrappers) {
        assert(wrapper.isLoaded, wrapper);
        if (wrapper == _walls) {
          continue; //no need to reset, stops a flash on screen
        }
        wrapper.reset();
      }
    }
  }

  final SnakeWrapper snakeWrapper = SnakeWrapper();

  void start() {
    play(SfxType.startMusic);
    for (final WrapperNoEvents wrapper in wrappers) {
      wrapper.start();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(noEventsWrapper);
    wrappers.addAll(<WrapperNoEvents>[snakeWrapper, _walls]);
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

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    if (PacmanGame.stepDebug && game.paused) {
      game.stepEngine();
    }
  }

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
