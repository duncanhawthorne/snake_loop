import 'dart:ui';

import 'package:flame_forge2d/body_component.dart';

import '../../utils/constants.dart';
import '../pacman_game.dart';
import 'physics_ball.dart';

mixin ScaledBodyRender on BodyComponent<PacmanGame> {
  @override
  void render(Canvas canvas) {
    if (spriteVsPhysicsScaleConstant) {
      super.render(canvas);
      return;
    }

    final double s = spriteVsPhysicsScale;
    canvas
      ..save()
      ..scale(s)
      ..translate(position.x * (1 - 1 / s), position.y * (1 - 1 / s));
    super.render(canvas);
    canvas.restore();

    if (drawDebugBoxes) {
      super.render(canvas);
    }
  }
}
