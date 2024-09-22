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

  List<SnakeBodyBit> activeBodyBits = [];
  List<SnakeBodyBit> spareBitsList = [];
  late final SnakeBodyEnd snakeEnd =
      SnakeBodyEnd(position: Vector2(0, 0), snakeHead: this);

  int _snakeBitsLimit = 0;
  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.active,
    radius: radius * (1 - hitboxGenerosity),
    position: Vector2.all(radius),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(_hitbox);
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
    for (SnakeBodyBit bit in activeBodyBits) {
      bit.deactivate();
    }
    for (SnakeBodyBit bit in spareBitsList) {
      bit.deactivate();
    }
    position = Vector2(0, 0);
    snakeEnd.position = position;
    _snakeBitsLimit = 3;
  }

  bool _atStartingPosition() {
    return position.x == 0 && position.y == 0;
  }

  void _addSnakeBitAtPosition(Vector2 targetPosition) {
    if (spareBitsList.isNotEmpty) {
      spareBitsList[0].activate(targetPosition);
    } else {
      world.snakeWrapper.add(SnakeBodyBit(position: targetPosition));
    }
  }

  void _removeSnakeBit(SnakeBodyBit bit) {
    bit.deactivate();
    //bit.removeFromParent();
  }

  bool get shouldSnakeMove =>
      game.isGameLive &&
      game.stopwatchMilliSeconds > 0 &&
      !(game.overlays.isActive(GameScreen.loseDialogKey)) &&
      !game.world.gameWonOrLost;

  void _moveHeadOfSnake(double dt) {
    position = position - world.direction * dt;
  }

  void _addToStartOfSnake() {
    if (!_atStartingPosition()) {
      if (activeBodyBits.isEmpty) {
        _addSnakeBitAtPosition(position);
      } else if ((position - activeBodyBits.last.position).length >
          width * snakeGapFactor) {
        // rather than set new position at current position
        // set the right distance away in that direction
        // if device is lagging stops visual artifacts of missing frames
        // showing as gaps in the snake body
        Vector2 targetPositionForNewSnakeBit = activeBodyBits.last.position +
            (position - activeBodyBits.last.position).normalized() *
                width *
                snakeGapFactor;
        _addSnakeBitAtPosition(targetPositionForNewSnakeBit);
      }
    } else {
      debug("atStartingPosition"); //shouldn't run
    }
  }

  void _removeFromEndOfSnake() {
    if (activeBodyBits.length > _snakeBitsLimit) {
      snakeEnd.moveTo(activeBodyBits[1].position);
      _removeSnakeBit(activeBodyBits[0]);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (shouldSnakeMove) {
      _moveHeadOfSnake(dt);
      _addToStartOfSnake();
      _removeFromEndOfSnake();
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
    } else if (other is SnakeBodyBit) {
      if (other != activeBodyBits.last) {
        // don't count collisions with snakeBit just added
        game.handleLoseGame();
        debug("trail intersect");
      }
    } else if (other is MazeWallRectangleVisual) {
      game.handleLoseGame();
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (pellet is Food) {
      _snakeBitsLimit += 4;
      world.pellets.pelletsRemainingNotifier.value -= 1;
      pellet.removeFromParent();
    }
  }
}
