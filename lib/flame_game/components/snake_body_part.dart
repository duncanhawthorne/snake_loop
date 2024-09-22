import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../maze.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_wrapper.dart';

final Vector2 _offscreen =
    Vector2(maze.mazeWidth / 2 * 100, maze.mazeHeight / 2 * 100);

class SnakeBodyBit extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyBit({required super.position, required this.snakeWrapper})
      : super(radius: snakeRadius, anchor: Anchor.center, paint: snakePaint);

  SnakeWrapper snakeWrapper;
  bool get isActive => _isActive;
  bool _isActive = true;

  void activate({required Vector2 targetPosition}) {
    _isActive = true;
    //move it to the last position in bodyBits so order is right for activeBits
    snakeWrapper.bodyBits.remove(this);
    snakeWrapper.bodyBits.add(this);
    position.setFrom(targetPosition);
  }

  void deactivate() {
    _isActive = false;
    position.setFrom(_offscreen);
  }

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.passive,
    radius: radius,
    position: Vector2.all(radius),
    anchor: Anchor.center,
  );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(_hitbox);
    snakeWrapper.bodyBits.add(this);
    activate(targetPosition: position);
  }

  @override
  Future<void> onRemove() async {
    deactivate();
    snakeWrapper.bodyBits.remove(this);
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
    if (pellet is Food && snakeWrapper.snakeNeck != this) {
      pellet.position = snakeWrapper.getSafePositionForFood();
      //dont increment score as not captured by head
    }
  }
}
