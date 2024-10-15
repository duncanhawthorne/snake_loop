import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'snake_wrapper.dart';

class SnakeBodyEnd extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        IgnoreEvents,
        CollisionCallbacks {
  SnakeBodyEnd({required super.position})
      : super(radius: snakeRadius, anchor: Anchor.center, paint: snakePaint);

  void slideTo(Vector2 targetPosition, {Function()? onComplete}) {
    removeEffects(this);
    add(MoveToPositionEffect(targetPosition,
        duration: distanceBetweenSnakeBits / world.direction.length,
        onComplete: onComplete));
  }

  void instantMoveTo(Vector2 targetPosition) {
    removeEffects(this);
    position = targetPosition;
  }
}
