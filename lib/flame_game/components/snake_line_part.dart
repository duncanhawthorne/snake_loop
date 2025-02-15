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
final Vector2 _offscreenV = Vector2(_offscreen, _offscreen);
final Vector2 _startSize = Vector2(1, 1);

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
  final SnakeBodyBit oneForward;
  late final Vector2 forwardPosition = oneForward.position;
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
      final Vector2 backwardPosition = oneBack!.position;
      position
        ..setFrom(forwardPosition)
        ..add(backwardPosition)
        ..scale(0.5);
      width = forwardPosition.distanceTo(backwardPosition);
      angle = atan2(forwardPosition.y - backwardPosition.y,
          forwardPosition.x - backwardPosition.x);
    }
  }
}
