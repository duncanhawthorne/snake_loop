import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';
import '../pacman_world.dart';
import 'snake_body_part.dart';
import 'snake_wrapper.dart';

final Paint _snakeLinePaint = Paint()..color = Palette.seed.color;

class SnakeLineBit extends RectangleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  SnakeLineBit({required this.oneForward, required this.oneBack})
      : super(
            position: Vector2(0, 0),
            size: Vector2(1, 1),
            anchor: Anchor.center,
            paint: _snakeLinePaint,
            priority: -10);

  SnakeBodyBit oneBack;
  SnakeBodyBit oneForward;

  @override
  void onLoad() {
    super.onLoad();
    opacity = 0.5;
    height = snakeRadius * 2;
  }

  void fixPosition() {
    if (!oneForward.isMounted ||
        !oneBack.isMounted ||
        oneForward.isRemoving ||
        oneBack.isRemoving) {
      position.setAll(0);
      width = 0;
      removeFromParent();
    } else {
      position
        ..setFrom(oneForward.position)
        ..add(oneBack.position)
        ..scale(1 / 2);
      //..x += snakeRadius
      //..y += snakeRadius;
      width = oneForward.position.distanceTo(oneBack.position);
      angle = atan2(oneForward.position.y - oneBack.position.y,
          oneForward.position.x - oneBack.position.x);
    }
  }
}
