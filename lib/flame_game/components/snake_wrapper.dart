import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'snake_body_part.dart';
import 'snake_head.dart';
import 'wrapper_no_events.dart';

final Paint snakePaint = Paint()..color = Palette.seed.color;
final double snakeRadius = maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2;
final double distanceBetweenSnakeBits = snakeRadius * 2;

class SnakeWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = 1;

  late final SnakeHead snakeHead =
      SnakeHead(position: Vector2(0, 0), snakeWrapper: this);
  final List<SnakeBodyBit> bodyBits = <SnakeBodyBit>[];
  Iterable<SnakeBodyBit> get _activeBodyBits =>
      bodyBits.where((SnakeBodyBit item) => item.isActive);
  bool neckSlideInProgress = false;

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);

  int _snakeBitsLimit = 0;
  SnakeBodyBit? snakeNeck;

  final Food food = Food(position: Vector2(0, 0));

  bool get _activeGameplay =>
      game.isGameLive &&
      game.stopwatchMilliSeconds > 0 &&
      !(game.overlays.isActive(GameScreen.loseDialogKey)) &&
      !game.world.gameWonOrLost;

  final Vector2 _oneUsePosition = Vector2.all(0);
  Vector2 getSafePositionForFood() {
    bool safePos = false;
    safePos = false;
    while (!safePos) {
      _oneUsePosition
        ..x = (game.random.nextDouble() - 0.5) *
            (maze.mazeWidth - 2 * maze.blockWidth - snakeRadius * 2)
        ..y = (game.random.nextDouble() - 0.5) *
            (maze.mazeHeight - 2 * maze.blockWidth - snakeRadius * 2);
      safePos = true;
      for (SnakeBodyBit bit in _activeBodyBits) {
        if ((bit.position - _oneUsePosition).length <
            snakeHead.width * (1 + hitboxGenerosity)) {
          safePos = false;
        }
      }
    }
    return _oneUsePosition;
  }

  void _snakeBitsReset() {
    for (SnakeBodyBit bit in bodyBits) {
      bit.removeFromParent();
    }
  }

  void extendSnake() {
    _snakeBitsLimit += 4;
  }

  @override
  void reset() {
    snakeHead.reset();
    _snakeBitsReset();
    snakeNeck = null;
    neckSlideInProgress = false;
    world.pellets.pelletsRemainingNotifier.value =
        1 + 2 * (game.level.number - 1);
    _snakeBitsLimit = 3;
    numberOfDeathsNotifier.value = 0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(snakeHead);
    add(food..position = getSafePositionForFood());
    game.camera.follow(snakeHead);
    reset();
  }

  void _addToStartOfSnake() {
    assert(!snakeHead.atStartingPosition);
    if (_activeBodyBits.isEmpty) {
      add(SnakeBodyBit(position: snakeHead.position, snakeWrapper: this)
        ..becomeNeck());
    } else if (!neckSlideInProgress) {
      neckSlideInProgress = true;
      add(SnakeBodyBit(position: snakeHead.position, snakeWrapper: this)
        ..current = CharacterState.slidingToAddToNeck);
    }
  }

  void _removeFromEndOfSnake() {
    if (_activeBodyBits.length > _snakeBitsLimit) {
      final SnakeBodyBit currentEnd = _activeBodyBits.elementAt(0);
      final SnakeBodyBit newEnd = _activeBodyBits.elementAt(0 + 1);
      assert(currentEnd != newEnd); //ensure elements not repeated in list
      currentEnd
        ..current = CharacterState.slidingToRemove
        ..slideTo(newEnd.position,
            onComplete: () => currentEnd.removeFromParent());
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_activeGameplay) {
      snakeHead.move(dt);
      _addToStartOfSnake();
      _removeFromEndOfSnake();
    }
  }
}
