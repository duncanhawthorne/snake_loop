import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../utils/helper.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_body_part.dart';
import 'snake_end.dart';
import 'snake_wrapper.dart';
import 'wall.dart';

double snakeGapFactor = 1.02;

class SnakeHead extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        CollisionCallbacks,
        IgnoreEvents {
  SnakeHead({required super.position})
      : super(
            paint: snakePaint,
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            priority: 100);

  SnakeBodyEnd snakeEnd = SnakeBodyEnd(position: Vector2(0, 0));
  final Vector2 _snakeLastPosition = Vector2(0, 0);
  List<SnakeBodyBit> snakeActiveBitsList = [];
  List<SnakeBodyBit> snakeSpareBitsList = [];
  int _maxSnakeBits = 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.active,
      radius: radius * (1 - hitboxGenerosity),
      position: Vector2.all(radius),
      anchor: Anchor.center,
    ));
    debugMode = false;
    world.snakeWrapper.add(snakeEnd);
    reset();
  }

  @override
  Future<void> onRemove() async {
    super.onRemove();
  }

  void reset() {
    for (Component child in world.snakeWrapper.children) {
      if (child is SnakeBodyBit) {
        child.deactivate();
      }
    }
    for (SnakeBodyBit bit in snakeActiveBitsList) {
      bit.deactivate();
    }
    for (SnakeBodyBit bit in snakeSpareBitsList) {
      bit.deactivate();
    }
    position = Vector2(0, 0); //reset it
    _maxSnakeBits = 3; //reset it
    snakeEnd.position = Vector2(0, 0);
    _snakeLastPosition.setFrom(position);
  }

  bool atStartingPosition() {
    return position.x == 0 && position.y == 0;
  }

  void addSnakeBitAtPosition(Vector2 targetPosition) {
    _snakeLastPosition.setFrom(targetPosition);
    if (snakeSpareBitsList.isNotEmpty) {
      snakeSpareBitsList[0].activate(targetPosition);
    } else {
      world.snakeWrapper.add(SnakeBodyBit(position: targetPosition));
    }
  }

  void removeSnakeBit(SnakeBodyBit bit) {
    bit.deactivate();
    //bit.removeFromParent();
  }

  bool get shouldSnakeMove =>
      game.isGameLive &&
      game.stopwatchMilliSeconds > 0 &&
      !(game.overlays.isActive(GameScreen.loseDialogKey)) &&
      !game.world.gameWonOrLost;

  @override
  void update(double dt) {
    super.update(dt);

    if (shouldSnakeMove) {
      position = position - world.direction * dt;
      if (!atStartingPosition()) {
        if (snakeActiveBitsList.isEmpty) {
          addSnakeBitAtPosition(position);
        } else if ((position - _snakeLastPosition).length >
            width * snakeGapFactor) {
          // rather than set new position at current position
          // set the right distance away in that direction
          // if device is lagging stops visual artifacts of missing frames
          // showing as gaps in the snake body
          Vector2 targetPositionForNewSnakeBit = _snakeLastPosition +
              (position - _snakeLastPosition).normalized() *
                  width *
                  snakeGapFactor;
          addSnakeBitAtPosition(targetPositionForNewSnakeBit);
        }
      }
      if (snakeActiveBitsList.length > _maxSnakeBits) {
        snakeEnd.moveTo(snakeActiveBitsList[1].position);
        removeSnakeBit(snakeActiveBitsList[0]);
      }
    }
  }

  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    _onCollideWith(other);
  }

  void _onCollideWith(PositionComponent other) {
    if (other is Pellet) {
      _onCollideWithPellet(other);
    } else if (other is SnakeHead) {
      //world.reset();
    } else if (other is SnakeBodyBit) {
      if (other != snakeActiveBitsList.last) {
        game.handleLoseGame();
        debug("trail intersect");
      }
    } else if (other is MazeWallRectangleVisual) {
      game.handleLoseGame();
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (pellet is Food) {
      _maxSnakeBits += 4;
      world.pellets.pelletsRemainingNotifier.value -= 1;
      pellet.removeFromParent();
    }
  }
}
