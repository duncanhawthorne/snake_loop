import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../game_screen.dart';

final Paint _pelletPaint = Paint()..color = Palette.text.color;

Widget circleIcon() {
  return CustomPaint(
      size: const Size(statusWidgetHeight * statusWidgetHeightFactor,
          statusWidgetHeight * statusWidgetHeightFactor),
      painter: PacmanPainter());
}

const _pacmanRectStatusBarSize = statusWidgetHeight * statusWidgetHeightFactor;
final Rect _pacmanRectStatusBar = Rect.fromCenter(
    center: const Offset(
        _pacmanRectStatusBarSize / 2, _pacmanRectStatusBarSize / 2),
    width: _pacmanRectStatusBarSize.toDouble(),
    height: _pacmanRectStatusBarSize.toDouble());

class PacmanPainter extends CustomPainter {
  PacmanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(_pacmanRectStatusBar, 0, tau, true, _pelletPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
