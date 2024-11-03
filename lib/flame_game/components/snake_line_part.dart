import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';
import '../pacman_world.dart';
import 'snake_body_part.dart';
import 'snake_wrapper.dart';

final redPaint = Paint()..color = Palette.warning.color;

class SnakeLineBit extends RectangleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  SnakeLineBit({required this.oneForward, required this.oneBack})
      : super(
            position: Vector2(0, 0),
            size: Vector2(1, 1),
            anchor: Anchor.center,
            paint: redPaint,
            priority: -10);

  SnakeBodyBit oneBack;
  SnakeBodyBit oneForward;

  @override
  void onLoad() {
    super.onLoad();
    height = snakeRadius * 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!oneForward.isMounted || !oneBack.isMounted) {
      removeFromParent();
      return;
    }
    if (oneForward.current == CharacterState.slidingToRemove ||
        oneForward.current == CharacterState.slidingToAddToNeck ||
        oneBack.current == CharacterState.slidingToRemove ||
        oneBack.current == CharacterState.slidingToAddToNeck) {
      position.setFrom(oneForward.position);
      position.add(oneBack.position);
      position.scale(1 / 2);
      width = oneForward.position.distanceTo(oneBack.position);
      angle = atan2(oneForward.position.y - oneBack.position.y,
          oneForward.position.x - oneBack.position.x);
    }
  }
}
