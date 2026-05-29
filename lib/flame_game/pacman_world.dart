import 'dart:async';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../utils/constants.dart';
import 'components/blocking_bar_layer.dart';
import 'components/ghost_layer.dart';
import 'components/pacman_layer.dart';
import 'components/pellet_layer.dart';
import 'components/wall_dynamic_layer.dart';
import 'components/wall_layer.dart';
import 'components/wrapper_no_events.dart';
import 'managers/death_reset.dart';
import 'managers/drag_rotation.dart';
import 'managers/engine_auto_pauser.dart';
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

  final Vector2 gravitySign = Vector2.zero();

  late final DragRotation dragRotate = DragRotation(game: game, world: this);

  final List<WrapperNoEvents> wrappers = <WrapperNoEvents>[];
  final WrapperNoEvents noEventsWrapper = WrapperNoEvents();

  final Pacmans pacmans = Pacmans();
  final Ghosts ghosts = Ghosts();
  final PelletWrapper pellets = PelletWrapper();
  final WallWrapper _walls = WallWrapper();
  final BlockingBarWrapper _blocking = BlockingBarWrapper();
  final MovingWallWrapper _movingWalls = MovingWallWrapper();
  final DeathReset deathReset = DeathReset();
  final EngineAutoPauser autoPauser = EngineAutoPauser();

  void reset({bool firstRun = false}) {
    dragRotate.reset();
    if (!firstRun) {
      for (final WrapperNoEvents wrapper in wrappers) {
        assert(wrapper.isLoaded, wrapper);
        wrapper.reset();
      }
    }
  }

  void start() {
    for (final WrapperNoEvents wrapper in wrappers) {
      wrapper.start();
    }
  }

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
      deathReset,
      autoPauser,
      game.session,
      game.lifecycle,
      game.playback,
      game.dialogs,
    ]);
    for (final WrapperNoEvents wrapper in wrappers) {
      noEventsWrapper.add(wrapper);
    }
    reset(firstRun: true);
  }

  @override
  void onRemove() {
    dragRotate.reset();
    wrappers.clear();
    super.onRemove();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    dragRotate.canvasRadius = min(game.canvasSize.x, game.canvasSize.y) / 2;
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    dragRotate.onDragStart(event);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    dragRotate.onDragUpdate(event);
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    dragRotate.onDragEnd(event);
  }
}
