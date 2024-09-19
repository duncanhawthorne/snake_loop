import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../utils/helper.dart';
import '../game_screen.dart';
import '../icons/pacman_sprites.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_body_part.dart';
import 'snake_end.dart';
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
            paint: greenSnakePaint,
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            priority: 100);

  SnakeBodyEnd snakeEnd = SnakeBodyEnd(position: Vector2(0, 0));

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.active,
      radius: radius * (1 - 0.5),
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

  final Vector2 _snakeLastPosition = Vector2(0, 0);
  List<SnakeBodyBit> snakeBitsList = [];
  int _maxSnakeBits = 0;

  void reset() {
    for (Component child in world.snakeWrapper.children) {
      if (child is SnakeBodyBit) {
        child.removeFromParent();
      }
    }
    position = Vector2(0, 0); //reset it
    _maxSnakeBits = 3; //reset it
    snakeEnd.position = Vector2(0, 0);
    _snakeLastPosition.setFrom(position);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (game.isGameLive &&
        game.stopwatchMilliSeconds > 0 &&
        !(game.overlays.isActive(GameScreen.loseDialogKey)) &&
        !game.world.gameWonOrLost) {
      position = position - world.direction * dt;
      /*
      if (position.x.abs() > maze.mazeWidth / 2 ||
          position.y.abs() > maze.mazeHeight / 2) {
        game.handleLoseGame();
      }

       */
      if ((position - _snakeLastPosition).length > width * snakeGapFactor ||
          snakeBitsList.isEmpty) {
        _snakeLastPosition.setFrom(position);
        world.snakeWrapper.add(SnakeBodyBit(position: position));
      }
      if (snakeBitsList.length > _maxSnakeBits) {
        snakeEnd.moveTo(snakeBitsList[1].position);
        snakeBitsList[0].removeFromParent();
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
      if (other != snakeBitsList.last) {
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
