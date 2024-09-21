import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_wrapper.dart';

final Vector2 offscreen =
    Vector2(maze.mazeWidth / 2 * 100, maze.mazeHeight / 2 * 100);

class SnakeBodyBit extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyBit({required super.position})
      : super(
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            paint: snakePaint);

  void activate(Vector2 targetPosition) {
    if (!world.snakeWrapper.snakeHead.snakeActiveBitsList.contains(this)) {
      world.snakeWrapper.snakeHead.snakeActiveBitsList.add(this);
    }
    world.snakeWrapper.snakeHead.snakeSpareBitsList.remove(this);
    position.setFrom(targetPosition);
  }

  void deactivate() {
    world.snakeWrapper.snakeHead.snakeActiveBitsList.remove(this);
    if (!world.snakeWrapper.snakeHead.snakeSpareBitsList.contains(this)) {
      world.snakeWrapper.snakeHead.snakeSpareBitsList.add(this);
    }
    position.setFrom(offscreen);
  }

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
    activate(position);
  }

  @override
  Future<void> onRemove() async {
    deactivate();
    world.snakeWrapper.snakeHead.snakeActiveBitsList.remove(this);
    world.snakeWrapper.snakeHead.snakeSpareBitsList.remove(this);
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
