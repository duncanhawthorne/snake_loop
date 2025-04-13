import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';

import '../../utils/helper.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_body_part.dart';
import 'snake_wrapper.dart';
import 'wall.dart';

const double _spriteFactor = 1.4;

class SnakeHead extends SpriteComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        CollisionCallbacks,
        IgnoreEvents {
  SnakeHead({required super.position, required this.snakeWrapper})
    : super(
        paint: snakePaint,
        size: Vector2.all(snakeRadius * 2 * _spriteFactor),
        anchor: Anchor.center,
        priority: PacmanGame.stepDebug ? -1 : 100,
      );

  SnakeWrapper snakeWrapper;
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

  void reset() {
    position.setAll(0);
    angle = -atan2(world.downDirection.x, world.downDirection.y) + tau / 2;
  }

  bool get atStartingPosition => position.x == 0 && position.y == 0;

  void move(double dt) {
    position.addScaled(world.downDirection, -dt);
    angle = -atan2(world.downDirection.x, world.downDirection.y) + tau / 2;
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
        game.numberOfDeathsNotifier.value++;
        logGlobal("trail intersect");
      }
    } else if (other is WallRectangleVisual) {
      game.numberOfDeathsNotifier.value++;
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (pellet is Food) {
      snakeWrapper.extendSnake();
      pellet
        ..position = snakeWrapper.getSafePositionForFood()
        ..angle = -atan2(world.downDirection.x, world.downDirection.y);
      world.pellets.pelletsRemainingNotifier.value -= 1;
    }
  }
}
