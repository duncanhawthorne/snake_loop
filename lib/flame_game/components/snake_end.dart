import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../icons/pacman_sprites.dart';
import '../maze.dart';
import '../pacman_world.dart';
import 'snake_body_part.dart';
import 'snake_head.dart';

class SnakeBodyEnd extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyEnd({required super.position})
      : super(
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            paint: greenSnakePaint);

  SnakeBodyBit? targetBodyBit;

  void moveTo(Vector2 targetPosition) {
    removeEffects(this);
    add(MoveToPositionEffect(targetPosition,
        duration: snakeGapFactor * width / world.direction.length));
  }

  @override
  void update(double dt) {
    if (targetBodyBit == null ||
        !world.snakeWrapper.snakeHead.snakeBitsList.contains(targetBodyBit)) {
      if (world.snakeWrapper.snakeHead.snakeBitsList.isNotEmpty) {
        targetBodyBit = world.snakeWrapper.snakeHead.snakeBitsList[0];
        //moveTo(targetBodyBit!.position);
      }
    }
  }
}
