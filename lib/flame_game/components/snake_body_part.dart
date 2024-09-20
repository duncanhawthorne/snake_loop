import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_wrapper.dart';

class SnakeBodyBit extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyBit({required super.position})
      : super(
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            paint: greenSnakePaint);

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: radius,
      position: Vector2.all(radius),
      anchor: Anchor.center,
    ));

    world.snakeWrapper.snakeHead.snakeBitsList.add(this);
  }

  @override
  Future<void> onRemove() async {
    world.snakeWrapper.snakeHead.snakeBitsList.remove(this);
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollision(intersectionPoints, other);
    _onCollideWith(other);
  }

  void _onCollideWith(PositionComponent other) {
    if (other is Pellet) {
      //debug(["snake body bit collide", other]);
      _onCollideWithPellet(other);
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (pellet is Food) {
      pellet.removeFromParent();
      //world.snakeWrapper.snakeHead.addNewTargetPellet();
    }
  }
}
