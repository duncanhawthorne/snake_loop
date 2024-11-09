import 'dart:math';

import 'package:flame/components.dart';

import '../pacman_world.dart';
import 'snake_body_part.dart';
import 'snake_wrapper.dart';

class SnakeLineBit extends RectangleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  SnakeLineBit({required this.oneForward, required this.oneBack})
      : super(
            position: Vector2(0, 0),
            size: Vector2(1, 1),
            anchor: Anchor.center,
            paint: snakePaint,
            priority: -10);

  SnakeBodyBit oneBack;
  SnakeBodyBit oneForward;

  @override
  void onLoad() {
    super.onLoad();
    height = snakeRadius * 2;
  }

  void fixPosition() {
    if (!oneForward.isMounted || !oneBack.isMounted) {
      position.setAll(0);
      width = 0;
      removeFromParent();
      return;
    }
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

  @override
  void update(double dt) {
    super.update(dt);
    fixPosition();
  }
}
