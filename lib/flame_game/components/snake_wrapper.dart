import 'dart:ui';

import 'package:flame/components.dart';

import '../../style/palette.dart';
import '../../utils/helper.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'snake_body_part.dart';
import 'snake_end.dart';
import 'snake_head.dart';
import 'wrapper_no_events.dart';

final Paint snakePaint = Paint()..color = Palette.seed.color;
final double snakeRadius = maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2;
final double distanceBetweenSnakeBits = snakeRadius * 2;

class SnakeWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final priority = 1;

  late final SnakeHead snakeHead =
      SnakeHead(position: Vector2(0, 0), snakeWrapper: this);
  List<SnakeBodyBit> activeBodyBits = [];
  List<SnakeBodyBit> spareBodyBits = [];
  late final SnakeBodyEnd snakeEnd = SnakeBodyEnd(position: Vector2(0, 0));
  int _snakeBitsLimit = 0;
  SnakeBodyBit get snakeNeck => activeBodyBits.last;

  bool get _activeGameplay =>
      game.isGameLive &&
      game.stopwatchMilliSeconds > 0 &&
      !(game.overlays.isActive(GameScreen.loseDialogKey)) &&
      !game.world.gameWonOrLost;

  final _oneUsePosition = Vector2.all(0);
  Vector2 getSafePositionForFood() {
    bool safePos = false;
    safePos = false;
    while (!safePos) {
      _oneUsePosition
        ..x = (game.random.nextDouble() - 0.5) * maze.mazeHeight * 0.8
        ..y = (game.random.nextDouble() - 0.5) * maze.mazeHeight * 0.8;
      safePos = true;
      for (SnakeBodyBit bit in activeBodyBits) {
        if ((bit.position - _oneUsePosition).length <
            snakeHead.width * (1 + hitboxGenerosity)) {
          safePos = false;
        }
      }
    }
    return _oneUsePosition;
  }

  void _snakeBitsReset() {
    for (SnakeBodyBit bit in activeBodyBits) {
      bit.deactivate();
    }
    for (SnakeBodyBit bit in spareBodyBits) {
      bit.deactivate();
    }
    for (Component child in children) {
      if (child is SnakeBodyBit) {
        if (!spareBodyBits.contains(child)) {
          debug("child not in spareBodyBits"); //shouldn't happen
        }
        child.deactivate();
      }
    }
  }

  void extendSnake() {
    _snakeBitsLimit += 4;
  }

  @override
  void reset() {
    snakeHead.reset();
    _snakeBitsReset();
    snakeEnd.position = snakeHead.position;
    world.pellets.pelletsRemainingNotifier.value =
        1 + 2 * (world.level.number - 1);
    _snakeBitsLimit = 3;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(snakeHead);
    add(snakeEnd);
    add(Food(position: getSafePositionForFood()));
    game.camera.follow(snakeHead);
    reset();
  }

  void _addSnakeBitAtPosition(Vector2 targetPosition) {
    if (spareBodyBits.isNotEmpty) {
      spareBodyBits[0].activate(targetPosition: targetPosition);
    } else {
      add(SnakeBodyBit(position: targetPosition, snakeWrapper: this));
    }
  }

  void _removeSnakeBit(SnakeBodyBit bit) {
    bit.deactivate();
  }

  void _addToStartOfSnake() {
    if (!snakeHead.atStartingPosition) {
      if (activeBodyBits.isEmpty) {
        _addSnakeBitAtPosition(snakeHead.position);
      } else if ((snakeHead.position - snakeNeck.position).length >
          distanceBetweenSnakeBits) {
        // rather than set new position at current position
        // set the right distance away in that direction
        // if device is lagging stops visual artifacts of missing frames
        // showing as gaps in the snake body
        Vector2 targetPositionForNewSnakeBit = snakeNeck.position +
            (snakeHead.position - snakeNeck.position).normalized() *
                distanceBetweenSnakeBits;
        _addSnakeBitAtPosition(targetPositionForNewSnakeBit);
      }
    } else {
      debug("atStartingPosition"); //shouldn't run
    }
  }

  void _removeFromEndOfSnake() {
    if (activeBodyBits.length > _snakeBitsLimit) {
      snakeEnd.slideTo(activeBodyBits[1].position);
      _removeSnakeBit(activeBodyBits[0]);
    }
  }

  void _hideEndOfSnake() {
    snakeEnd.instantMoveTo(snakeHead.position); //hide it every frame
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_activeGameplay) {
      snakeHead.move(dt);
      _addToStartOfSnake();
      _removeFromEndOfSnake();
    } else {
      _hideEndOfSnake();
    }
  }
}
