import 'dart:async';
import 'dart:math';

import 'package:flame/camera.dart';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../../audio/sounds.dart';
import 'components/blocking_bar_layer.dart';
import 'components/pellet_layer.dart';
import 'components/snake_wrapper.dart';
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
    with HasGameReference<PacmanGame>, DragCallbacks {
  final WrapperNoEvents noEventsWrapper = WrapperNoEvents();
  final PelletWrapper pellets = PelletWrapper();
  final WallWrapper _walls = WallWrapper();
  final TutorialWrapper _tutorial = TutorialWrapper();
  // ignore: unused_field
  final BlockingBarWrapper _blocking = BlockingBarWrapper();
  final List<WrapperNoEvents> wrappers = <WrapperNoEvents>[];

  final Map<int, double?> _fingersLastDragAngle = <int, double?>{};

  bool doingLevelResetFlourish = false;
  bool _cameraRotatableOnPacmanDeathFlourish = true;

  /// The gravity is defined in virtual pixels per second squared.
  /// These pixels are in relation to how big the [FixedResolutionViewport] is.

  void play(SfxType type) {
    const bool soundOn = true; //!(windows && !kIsWeb);
    if (soundOn) {
      game.audioController.playSfx(type);
    }
  }

  void resetAfterGameWin() {
    game.audioController.stopSfx(SfxType.ghostsScared);
    play(SfxType.endMusic);
  }

  void _cameraAndTimersReset() {
    //stop any rotation effect added to camera
    //note, still leaves flourish variable hot, so fix below
    removeEffects(game.camera.viewfinder);
    setMazeAngle(0);
    _cameraRotatableOnPacmanDeathFlourish = true;
    doingLevelResetFlourish = false;
  }

  void reset({bool firstRun = false}) {
    _cameraAndTimersReset();
    game.audioController.stopSfx(SfxType.ghostsScared);

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
    wrappers.addAll(<WrapperNoEvents>[snakeWrapper, _walls, _tutorial]);
    for (final WrapperNoEvents wrapper in wrappers) {
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

  final Vector2 _eventOffset = Vector2.zero();
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    game.resumeGame();
    _eventOffset.setValues(event.canvasStartPosition.x - game.canvasSize.x / 2,
        event.canvasStartPosition.y - game.canvasSize.y / 2);
    final double eventVectorLengthProportion =
        _eventOffset.length / (min(game.canvasSize.x, game.canvasSize.y) / 2);
    final double fingerCurrentDragAngle = atan2(_eventOffset.x, _eventOffset.y);
    if (_fingersLastDragAngle.containsKey(event.pointerId)) {
      if (_fingersLastDragAngle[event.pointerId] != null) {
        final double angleDelta = smallAngle(
            fingerCurrentDragAngle - _fingersLastDragAngle[event.pointerId]!);
        const double maxSpinMultiplierRadius = 0.75;
        final double spinMultiplier = 4 *
            game.level.spinSpeedFactor *
            min(1, eventVectorLengthProportion / maxSpinMultiplierRadius);

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
    if (_cameraRotatableOnPacmanDeathFlourish &&
        game.isLive &&
        game.openingScreenCleared &&
        !game.playbackMode) {
      setMazeAngle(game.camera.viewfinder.angle + angleDelta);
      if (!doingLevelResetFlourish && !game.isWonOrLost) {
        game.startRegularItems();
      }
    }
  }

  final Vector2 downDirection = Vector2.zero();
  double gravityXSign = 0;
  double gravityYSign = 0;

  void setMazeAngle(double angle) {
    game.recordAngle(angle);
    game.camera.viewfinder.angle = angle;
    downDirection
      ..setValues(-sin(angle), cos(angle))
      ..scale(game.level.levelSpeed);

    gravity = downDirection;
    gravityXSign = gravity.x.sign; //as referred to every frame
    gravityYSign = gravity.y.sign; //as referred to every frame
  }
}
