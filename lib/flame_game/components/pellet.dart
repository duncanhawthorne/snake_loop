import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../custom_world.dart';
import '../maze/maze.dart';

const double _pelletScaleFactor = 0.4;
final Vector2 _reusableVector = Vector2.zero(); //shared across all pellets

double get pelletScaleFactor => _pelletScaleFactor;
const double _spriteFactor = 1.2;

/// A collectible item that Pacman eats to gain points and progress.
class Pellet extends SpriteComponent
    with IgnoreEvents, HasWorldRef<CustomWorld> {
  Pellet({
    required super.position,
    required this.pelletsRemainingNotifier,
    double radiusFactor = 1,
    double hitBoxRadiusFactor = 1,
  }) : super(
         size: Vector2.all(
           _spriteFactor *
               2 *
               maze.dimensions.spriteWidth /
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
      position: _reusableVector..setAll(size.x / 2),
      anchor: Anchor.center,
    )..debugMode = false;
  }

  late final CustomWorld world = worldRef;

  double get radius => size.x / 2 / _spriteFactor;
  late final CircleHitbox _hitbox;
  final ValueNotifier<int> pelletsRemainingNotifier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_hitbox);
  }
}
