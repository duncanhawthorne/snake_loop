import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../dialogs/game_overlays.dart';

final Paint _pelletPaint = Paint()..color = Palette.text.color;

Widget circleIcon() {
  return CustomPaint(
      size: const Size(pacmanIconSize, pacmanIconSize),
      painter: PacmanPainter());
}

const _pacmanRectStatusBarSize = pacmanIconSize;
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
