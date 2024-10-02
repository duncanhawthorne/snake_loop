import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
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
  bool get isActive => current == CharacterState.active;
  bool get isMid => current == CharacterState.mid;
  bool get isDeactive => current == CharacterState.deactive;

  CharacterState current = CharacterState.active;

  void slideTo(Vector2 targetPosition, {onComplete}) {
    removeEffects(this);
    add(MoveToPositionEffect(targetPosition,
        duration: distanceBetweenSnakeBits / world.direction.length,
        onComplete: onComplete));
  }

  void instantMoveTo(Vector2 targetPosition) {
    removeEffects(this);
    position = targetPosition;
  }

  void activate({required Vector2 targetPosition}) {
    current = CharacterState.active;
    _hitbox.collisionType = CollisionType.passive;
    //move it to the last position in bodyBits so order is right for activeBits
    snakeWrapper.bodyBits.remove(this);
    snakeWrapper.bodyBits.add(this);
    position.setFrom(targetPosition);
  }

  void midivate() {
    current = CharacterState.mid;
  }

  void deactivate() {
    current = CharacterState.deactive;
    _hitbox.collisionType = CollisionType.inactive;
    position.setFrom(_offscreen);
  }

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.passive,
    radius: radius * (1 - hitboxGenerosity),
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
    super.onRemove();
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

enum CharacterState { active, mid, deactive }
