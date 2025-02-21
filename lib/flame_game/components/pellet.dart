import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze.dart';

const double _pelletScaleFactor = 0.4;
final Vector2 _volatileInstantConsumeVector2 =
    Vector2.zero(); //shared across all pellets

double get pelletScaleFactor => _pelletScaleFactor;

class Pellet extends CircleComponent with IgnoreEvents {
  Pellet({
    required super.position,
    required this.pelletsRemainingNotifier,
    double radiusFactor = 1,
    double hitBoxRadiusFactor = 1,
  }) : super(
         radius: maze.spriteWidth / 2 * _pelletScaleFactor * radiusFactor,
         anchor: Anchor.center,
       ) {
    _hitbox = CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.active,
      radius: radius * hitBoxRadiusFactor,
      position: _volatileInstantConsumeVector2..setAll(radius),
      anchor: Anchor.center,
    );
  }

  late final CircleHitbox _hitbox;
  final ValueNotifier<int>
  pelletsRemainingNotifier; //passed in on creation of object rather than use slow to initialise HasGameReference for every single pellet

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_hitbox);
  }
}
