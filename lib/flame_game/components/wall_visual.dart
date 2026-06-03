import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';

final Paint _wallVisualPaint = Paint()..color = Palette.background.color;

//..filterQuality = FilterQuality.none
////..color = Color.fromARGB(50, 100, 100, 100)
//..isAntiAlias = false

/// Visual representation of a rectangular wall section.
class WallRectangleVisual extends RectangleComponent with IgnoreEvents {
  WallRectangleVisual({required super.position, required super.size})
    : super(anchor: Anchor.center, paint: _wallVisualPaint);
}

/// Visual representation of a circular wall section.
class WallCircleVisual extends CircleComponent with IgnoreEvents {
  WallCircleVisual({required super.radius, required super.position})
    : super(anchor: Anchor.center, paint: _wallVisualPaint);
}
