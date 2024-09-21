import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'snake_body_part.dart';
import 'snake_head.dart';
import 'snake_wrapper.dart';

class SnakeBodyEnd extends CircleComponent
    with
        HasWorldReference<PacmanWorld>,
        HasGameReference<PacmanGame>,
        IgnoreEvents,
        CollisionCallbacks {
  SnakeBodyEnd({required super.position})
      : super(
            radius: maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2,
            anchor: Anchor.center,
            paint: snakePaint);

  SnakeBodyBit? targetBodyBit;

  void moveTo(Vector2 targetPosition) {
    removeEffects(this);
    add(MoveToPositionEffect(targetPosition,
        duration: snakeGapFactor * width / world.direction.length));
  }

  @override
  void update(double dt) {
    if (!(game.isGameLive &&
        game.stopwatchMilliSeconds > 0 &&
        !(game.overlays.isActive(GameScreen.loseDialogKey)) &&
        !game.world.gameWonOrLost)) {
      position = world.snakeWrapper.snakeHead.position;
    }

    if (targetBodyBit == null ||
        !world.snakeWrapper.snakeHead.snakeBitsList.contains(targetBodyBit)) {
      if (world.snakeWrapper.snakeHead.snakeBitsList.isNotEmpty) {
        targetBodyBit = world.snakeWrapper.snakeHead.snakeBitsList[0];
        //moveTo(targetBodyBit!.position);
      }
    }
  }
}
