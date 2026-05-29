import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../utils/constants.dart';
import 'components/base_component.dart';
import 'components/blocking_bar_layer.dart';
import 'components/ghost_layer.dart';
import 'components/pacman_layer.dart';
import 'components/pellet_layer.dart';
import 'components/wall_dynamic_layer.dart';
import 'components/wall_layer.dart';
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

  final List<BaseComponent> _wrappers = <BaseComponent>[];
  final BaseComponent _noEvents = BaseComponent();

  final Pacmans pacmans = Pacmans();
  final Ghosts ghosts = Ghosts();
  final PelletWrapper pellets = PelletWrapper();
  final WallWrapper _walls = WallWrapper();
  final BlockingBarWrapper _blocking = BlockingBarWrapper();
  final MovingWallWrapper _movingWalls = MovingWallWrapper();
  final DeathReset deathReset = DeathReset();
  final EngineAutoPauser autoPauser = EngineAutoPauser();
  late final DragRotation dragRotate = DragRotation()..world = this;

  void reset({bool firstRun = false}) {
    if (!firstRun) {
      for (final BaseComponent wrapper in _wrappers) {
        assert(wrapper.isLoaded, wrapper);
        wrapper.reset();
      }
    }
  }

  void start() {
    for (final BaseComponent wrapper in _wrappers) {
      wrapper.start();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(_noEvents);
    _wrappers.addAll(<BaseComponent>[
      pacmans,
      ghosts,
      if (!enableRotationRaceMode) pellets,
      _walls,
      _blocking,
      if (enableMovingWalls) _movingWalls,
      deathReset,
      autoPauser,
      dragRotate,
      game.session,
      game.lifecycle,
      game.playback,
      game.dialogs,
    ]);
    for (final BaseComponent wrapper in _wrappers) {
      /// Add inside [noEventsWrapper] to minimise number of components in world
      /// Speeds up loops running through all child components
      /// Especially on drag events deliverAtPoint
      _noEvents.add(wrapper);
    }
    reset(firstRun: true);
  }

  @override
  void onRemove() {
    _wrappers.clear();
    super.onRemove();
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
