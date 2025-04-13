import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze.dart';
import '../pacman_world.dart';

const double _pelletScaleFactor = 0.4;
final Vector2 _volatileInstantConsumeVector2 =
    Vector2.zero(); //shared across all pellets

double get pelletScaleFactor => _pelletScaleFactor;
const double _spriteFactor = 1.2;

class Pellet extends SpriteComponent
    with IgnoreEvents, HasWorldReference<PacmanWorld> {
  Pellet({
    required super.position,
    required this.pelletsRemainingNotifier,
    double radiusFactor = 1,
    double hitBoxRadiusFactor = 1,
  }) : super(
         size: Vector2.all(
           _spriteFactor *
               2 *
               maze.spriteWidth /
               2 *
               _pelletScaleFactor *
               radiusFactor,
         ),
         anchor: Anchor.center,
       ) {
    _hitbox = CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.active,
      radius: radius * hitBoxRadiusFactor,
      position: _volatileInstantConsumeVector2..setAll(size.x / 2),
      anchor: Anchor.center,
    )..debugMode = false;
  }

  double get radius => size.x / 2 / _spriteFactor;
  late final CircleHitbox _hitbox;
  final ValueNotifier<int>
  pelletsRemainingNotifier; //passed in on creation of object rather than use slow to initialise HasGameReference for every single pellet

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('apple.png');
    angle = -atan2(world.downDirection.x, world.downDirection.y);
    add(_hitbox);
  }
}
