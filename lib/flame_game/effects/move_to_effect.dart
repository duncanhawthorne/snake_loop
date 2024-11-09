import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/animation.dart';

import '../components/snake_body_part.dart';

const int kResetPositionTimeMillis = 1000;

class MoveToPositionEffect extends MoveToEffect {
  MoveToPositionEffect(Vector2 destination,
      {Function()? onComplete,
      double duration = kResetPositionTimeMillis / 1000})
      : super(destination,
            EffectController(duration: duration, curve: Curves.linear),
            onComplete: onComplete);

  @override
  void apply(double progress) {
    super.apply(progress);
    if (target is SnakeBodyBit) {
      final SnakeBodyBit targetBit = target as SnakeBodyBit;
      // ignore: cascade_invocations
      targetBit.fixLineBits();
    }
  }
}
