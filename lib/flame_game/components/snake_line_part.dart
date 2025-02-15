import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'snake_body_part.dart';
import 'snake_wrapper.dart';

final Paint _snakeLinePaint = Paint()..color = Palette.seed.color;
// ignore: unused_element
final Paint _snakeLinePaintDebug = Paint()..color = Palette.warning.color;

const double _offscreen = 10000;
Vector2 _offscreenV = Vector2(_offscreen, _offscreen);
Vector2 _startSize = Vector2(1, 1);

class SnakeLineBit extends RectangleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents {
  SnakeLineBit({required this.oneForward, required this.oneBack})
      : super(
            position: _offscreenV,
            size: _startSize,
            anchor: Anchor.center,
            paint:
                PacmanGame.stepDebug ? _snakeLinePaintDebug : _snakeLinePaint,
            priority: PacmanGame.stepDebug ? 1000 : -10);

  SnakeBodyBit? oneBack;
  SnakeBodyBit oneForward;
  bool active = true;

  @override
  void onLoad() {
    super.onLoad();
    height = snakeRadius * (PacmanGame.stepDebug ? 0.5 : 2);
  }

  void hide() {
    if (active) {
      active = false;
      oneBack = null;
      position.setAll(_offscreen);
      width = 0;
    }
  }

  void fixPosition() {
    if (oneBack == null || !oneForward.active || !oneBack!.active) {
      hide();
    } else {
      active = true;
      position
        ..setFrom(oneForward.position)
        ..add(oneBack!.position)
        ..scale(1 / 2);
      width = oneForward.position.distanceTo(oneBack!.position);
      angle = atan2(oneForward.position.y - oneBack!.position.y,
          oneForward.position.x - oneBack!.position.x);
    }
  }
}
