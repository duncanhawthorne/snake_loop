import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../dialogs/game_overlays.dart';

final Paint _pelletPaint = Paint()..color = Palette.text.color;

Widget circleIcon() {
  return CustomPaint(
    size: const Size(circleIconSize, circleIconSize),
    painter: _CirclePainter(),
  );
}

final Rect _pacmanRectStatusBar = Rect.fromCenter(
  center: const Offset(circleIconSize / 2, circleIconSize / 2),
  width: circleIconSize.toDouble(),
  height: circleIconSize.toDouble(),
);

class _CirclePainter extends CustomPainter {
  _CirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(_pacmanRectStatusBar, 0, tau, true, _pelletPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
