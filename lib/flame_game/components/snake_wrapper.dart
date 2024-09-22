import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'snake_body_part.dart';
import 'snake_head.dart';
import 'wrapper_no_events.dart';

final Paint snakePaint = Paint()..color = Palette.seed.color;

class SnakeWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 1;

  SnakeHead snakeHead = SnakeHead(position: Vector2(0, 0));

  final _oneUsePosition = Vector2.all(0);
  bool _safePos = false;

  Vector2 _safePositionForNewPellet() {
    _safePos = false;
    while (!_safePos) {
      _oneUsePosition
        ..x = (game.random.nextDouble() - 0.5) * maze.mazeHeight * 0.8
        ..y = (game.random.nextDouble() - 0.5) * maze.mazeHeight * 0.8;
      _safePos = true;
      for (SnakeBodyBit bit in snakeHead.activeBodyBits) {
        if ((bit.position - _oneUsePosition).length <
            snakeHead.width * (1 + hitboxGenerosity)) {
          _safePos = false;
        }
      }
    }
    return _oneUsePosition;
  }

  void addNewTargetPellet() {
    add(Food(position: _safePositionForNewPellet()));
  }

  @override
  void reset() {
    snakeHead.reset();
    world.pellets.pelletsRemainingNotifier.value =
        1 + 2 * (world.level.number - 1);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(snakeHead);
    addNewTargetPellet();
    game.camera.follow(snakeHead);
    reset();
  }
}
