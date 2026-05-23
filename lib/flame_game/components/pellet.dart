import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze.dart';

class Pellet extends CircleComponent with IgnoreEvents {
  Pellet({
    required super.position,
    required this.pelletsRemainingNotifier,
    double radiusFactor = 1,
    double hitBoxRadiusFactor = 1,
  }) : super(
         radius:
             maze.dimensions.spriteWidth /
             2 *
             _pelletScaleFactor *
             radiusFactor,
         anchor: Anchor.center,
       ) {
    _hitbox = CircleHitbox(
      isSolid: true,
      collisionType: CollisionType.passive,
      radius: radius * hitBoxRadiusFactor,
      position: _reusableVector..setAll(radius),
      anchor: Anchor.center,
    );
  }

  static const double _pelletScaleFactor = 0.4;
  static final Vector2 _reusableVector = Vector2.zero();

  late final CircleHitbox _hitbox;
  final ValueNotifier<int> pelletsRemainingNotifier;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_hitbox);
    pelletsRemainingNotifier.value += 1;
  }

  @override
  Future<void> onRemove() async {
    _hitbox.removeFromParent();
    pelletsRemainingNotifier.value -= 1;
    super.onRemove();
  }
}
