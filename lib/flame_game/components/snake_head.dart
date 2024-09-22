import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../../utils/helper.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_body_part.dart';
import 'snake_wrapper.dart';
import 'wall.dart';

class SnakeHead extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        CollisionCallbacks,
        IgnoreEvents {
  SnakeHead({required super.position, required this.snakeWrapper})
      : super(
            paint: snakePaint,
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            priority: 100);

  SnakeWrapper snakeWrapper;

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
    reset();
  }

  @override
  Future<void> onRemove() async {
    super.onRemove();
  }

  void reset() {
    position = Vector2(0, 0);
  }

  bool get atStartingPosition => position.x == 0 && position.y == 0;

  void move(double dt) {
    position = position - world.direction * dt;
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
      if (other != snakeWrapper.snakeNeck) {
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
      snakeWrapper.extendSnake();
      pellet.position = snakeWrapper.getSafePositionForNewPellet();
      world.pellets.pelletsRemainingNotifier.value -= 1;
    }
  }
}
