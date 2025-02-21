import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../../style/palette.dart';

final Paint _wallVisualPaint =
    Paint()
      //..filterQuality = FilterQuality.none
      ////..color = Color.fromARGB(50, 100, 100, 100)
      //..isAntiAlias = false
      ..color = Palette.seed.color;
final Paint _wallGroundPaint =
    Paint()
      //..filterQuality = FilterQuality.none
      ////..color = Color.fromARGB(50, 100, 100, 100)
      //..isAntiAlias = false
      ..color = Palette.seed.color;

final BodyDef _staticBodyDef = BodyDef(type: BodyType.static);

class WallRectangleVisual extends RectangleComponent with IgnoreEvents {
  WallRectangleVisual({required super.position, required super.size})
    : super(anchor: Anchor.center, paint: _wallVisualPaint);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(
      RectangleHitbox(
        isSolid: true,
        collisionType: CollisionType.passive,
        position: size / 2,
        size: size,
        anchor: Anchor.center,
      )..debugMode = false,
    );
  }
}

class WallCircleVisual extends CircleComponent with IgnoreEvents {
  WallCircleVisual({required super.radius, required super.position})
    : super(anchor: Anchor.center, paint: _wallVisualPaint);
}

// ignore: always_specify_types
class WallGround extends BodyComponent with IgnoreEvents {
  WallGround({required super.fixtureDefs})
    : super(paint: _wallGroundPaint, bodyDef: _staticBodyDef);

  @override
  final int priority = -3;
}
