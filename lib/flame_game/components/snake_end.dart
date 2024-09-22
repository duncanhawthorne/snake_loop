import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'snake_head.dart';
import 'snake_wrapper.dart';

class SnakeBodyEnd extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        IgnoreEvents,
        CollisionCallbacks {
  SnakeBodyEnd({required super.position, required this.snakeHead})
      : super(
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            paint: snakePaint);

  SnakeHead snakeHead;

  void moveTo(Vector2 targetPosition) {
    removeEffects(this);
    add(MoveToPositionEffect(targetPosition,
        duration: snakeGapFactor * width / world.direction.length));
  }

  @override
  void update(double dt) {
    if (!snakeHead.shouldSnakeMove) {
      removeEffects(this);
      position = snakeHead.position; //hide it every frame
    }
  }
}
