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
import 'snake_line_part.dart';
import 'wrapper_no_events.dart';

final Paint snakePaint = Paint()..color = Palette.seed.color;
final double snakeRadius = maze.spriteWidth / 2 * Maze.pelletScaleFactor * 2;
final int snakeBitsOverlaps = 3;
final double distanceBetweenSnakeBits = snakeRadius * 2 / snakeBitsOverlaps;

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
  SnakeBodyBit? snakeBitSlidingToNeck;
  SnakeBodyBit? snakeBitSlidingToRemove;

  late final Food food = Food(
      position: Vector2(0, 0),
      pelletsRemainingNotifier: world.pellets.pelletsRemainingNotifier);

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
    for (Component child in children) {
      if (child is SnakeLineBit) {
        child.removeFromParent();
      }
    }
  }

  void extendSnake() {
    _snakeBitsLimit += 4 * snakeBitsOverlaps;
  }

  @override
  void reset() {
    snakeHead.reset();
    _snakeBitsReset();
    snakeNeck = null;
    snakeBitSlidingToNeck = null;
    snakeBitSlidingToRemove = null;
    neckSlideInProgress = false;
    world.pellets.pelletsRemainingNotifier.value =
        1 + 2 * (game.level.number - 1);
    _snakeBitsLimit = 3 * snakeBitsOverlaps;
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
      add(SnakeBodyBit(
          position: snakeHead.position, snakeWrapper: this, oneBack: snakeNeck)
        ..becomeSlidingToAddToNeck());
    }
  }

  bool get tooManyBits => _activeBodyBits.length > _snakeBitsLimit;

  void _removeFromEndOfSnake() {
    if (tooManyBits) {
      _activeBodyBits.elementAt(0).becomeSlidingToRemove();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_activeGameplay) {
      snakeHead.move(dt);
      _addToStartOfSnake();
      snakeBitSlidingToNeck?.updatePositionAsSlidingToAddToNeck();
      snakeBitSlidingToRemove?.updatePositionAsSlidingToRemove();
      _removeFromEndOfSnake();
    }
  }
}
