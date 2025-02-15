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
  SnakeLineBit({required SnakeBodyBit oneForward, required this.oneBack})
      : _oneForward = oneForward,
        super(
            position: _offscreenV,
            size: _startSize,
            anchor: Anchor.center,
            paint:
                PacmanGame.stepDebug ? _snakeLinePaintDebug : _snakeLinePaint,
            priority: PacmanGame.stepDebug ? 1000 : -10);

  SnakeBodyBit? oneBack;
  final SnakeBodyBit _oneForward;
  late final Vector2 _forwardPosition = _oneForward.position;
  bool _active = true;

  @override
  void onLoad() {
    super.onLoad();
    height = snakeRadius * (PacmanGame.stepDebug ? 0.5 : 2);
  }

  void _hide() {
    if (_active) {
      _active = false;
      oneBack = null;
      position.setAll(_offscreen);
      width = 0;
    }
  }

  void fixPosition() {
    if (oneBack == null || !_oneForward.active || !oneBack!.active) {
      _hide();
    } else {
      _active = true;
      final Vector2 backwardPosition = oneBack!.position;
      position
        ..setFrom(_forwardPosition)
        ..add(backwardPosition)
        ..scale(0.5);
      width = _forwardPosition.distanceTo(backwardPosition);
      angle = atan2(_forwardPosition.y - backwardPosition.y,
          _forwardPosition.x - backwardPosition.x);
    }
  }
}
