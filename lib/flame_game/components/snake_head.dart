import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../utils/helper.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'snake_body_part.dart';
import 'snake_wrapper.dart';
import 'wall.dart';

class SnakeHead extends SpriteComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        CollisionCallbacks,
        IgnoreEvents {
  SnakeHead({required this.snakeWrapper})
    : super(
        paint: snakePaint,
        size: Vector2.all(snakeRadius * 2 * _spriteFactor),
        anchor: Anchor.center,
        priority: PacmanGame.stepDebug ? -1 : 100,
      );

  static const double _spriteFactor = 1.4;

  final SnakeWrapper snakeWrapper;
  double get radius => size.x / 2 / _spriteFactor;

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.active,
    radius: radius * (1 - hitboxGenerosity),
    position: Vector2.all(size.x / 2),
    anchor: Anchor.center,
  )..debugMode = false;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('head.png');
    add(_hitbox);
    debugMode = false;
    reset();
  }

  void _updateAngle() {
    angle =
        -atan2(
          world.dragRotate.downDirection.x,
          world.dragRotate.downDirection.y,
        ) +
        tau / 2;
  }

  void reset() {
    position.setAll(0);
    _updateAngle();
  }

  bool get atStartingPosition => position.x == 0 && position.y == 0;

  void move(double dt) {
    position.addScaled(world.dragRotate.downDirection, -dt);
    _updateAngle();
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
    switch (other) {
      case Food():
        _onCollideWithFood(other);
      case SnakeBodyBit():
        if (other != snakeWrapper.snakeNeck) {
          // don't count collisions with snakeBit just added
          game.session.numberOfDeathsNotifier.value++;
          logGlobal("trail intersect");
        }
      case WallRectangleVisual():
        game.session.numberOfDeathsNotifier.value++;
    }
  }

  void _onCollideWithFood(Food food) {
    snakeWrapper.extendSnake();
    food
      ..position = snakeWrapper.getSafePositionForFood()
      ..angle = -atan2(
        world.dragRotate.downDirection.x,
        world.dragRotate.downDirection.y,
      );
    world.pellets.pelletsRemainingNotifier.value -= 1;
  }
}
