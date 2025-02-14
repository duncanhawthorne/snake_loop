import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../style/palette.dart';
import '../game_screen.dart';
import '../maze.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_body_part.dart';
import 'snake_head.dart';
import 'snake_line_part.dart';
import 'wrapper_no_events.dart';

final Paint snakePaint = Paint()..color = Palette.seed.color;
final double snakeRadius = maze.spriteWidth / 2 * pelletScaleFactor * 2;
final int snakeBitsOverlaps = 3;
final double distanceBetweenSnakeBits = snakeRadius * 2 / snakeBitsOverlaps;
Vector2 offscreen = Vector2(400, 400);

class SnakeWrapper extends WrapperNoEvents
    with HasWorldReference<PacmanWorld>, HasGameReference<PacmanGame> {
  @override
  final int priority = 1;

  late final SnakeHead snakeHead =
      SnakeHead(position: Vector2(0, 0), snakeWrapper: this);
  final List<SnakeBodyBit> bodyBits = <SnakeBodyBit>[];
  final List<SnakeBodyBit> spareBodyBits = <SnakeBodyBit>[];

  SnakeBodyBit? get snakeBitSlidingToNeck =>
      bodyBits.isEmpty ? null : bodyBits[bodyBits.length - 1];
  SnakeBodyBit? get snakeNeck =>
      bodyBits.length < 2 ? null : bodyBits[bodyBits.length - 2];
  SnakeBodyBit? get snakeBitSlidingToRemove => bodyBits[0];

  bool get _tooManyBits => bodyBits.length > snakeBitsLimit;
  bool get snakeBitsMissing => bodyBits.length < 2;

  int snakeBitsLimit = 0;

  late final Food food = Food(
      position: Vector2(0, 0),
      pelletsRemainingNotifier: world.pellets.pelletsRemainingNotifier);

  bool get _activeGameplay =>
      game.isLive &&
      game.stopwatchMilliSeconds > 0 &&
      !(game.overlays.isActive(GameScreen.loseDialogKey)) &&
      !game.isWonOrLost;

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
      for (SnakeBodyBit bit in bodyBits) {
        if ((bit.position - _oneUsePosition).length <
            snakeHead.width * (1 + hitboxGenerosity)) {
          safePos = false;
        }
      }
    }
    return _oneUsePosition;
  }

  void extendSnake() {
    snakeBitsLimit += 4 * snakeBitsOverlaps;
  }

  void _activateNthHitbox() {
    const int multy = 3;
    if (bodyBits.length > snakeBitsOverlaps * multy) {
      //far enough away from snakeHead
      bodyBits[bodyBits.length - snakeBitsOverlaps * multy].activateHitbox();
    }
  }

  void _topUpSpares() {
    for (int i = 0; i < 10 - spareBodyBits.length; i++) {
      final SnakeBodyBit x =
          SnakeBodyBit(position: offscreen, snakeWrapper: this);
      spareBodyBits.add(x);
      add(x);
    }
  }

  SnakeBodyBit _getSpare() {
    _topUpSpares();
    final SnakeBodyBit newBit = spareBodyBits[0]..activate();
    return newBit;
  }

  void addToStartOfSnake() {
    assert(!snakeHead.atStartingPosition);
    if (_tooManyBits) {
      return;
    }
    _getSpare().position = snakeHead.position;
    _activateNthHitbox();
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

  @override
  Future<void> reset() async {
    snakeHead.reset();
    _snakeBitsReset();
    world.pellets.pelletsRemainingNotifier.value =
        1 + 2 * (game.level.number - 1);
    snakeBitsLimit = 3 * snakeBitsOverlaps;
    game.numberOfDeathsNotifier.value = 0;
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    add(snakeHead);
    add(food..position = getSafePositionForFood());
    game.camera.follow(snakeHead);
    //topUpSpares();
    await reset();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_activeGameplay) {
      snakeHead.move(dt);
      if (snakeBitsMissing) {
        addToStartOfSnake();
        addToStartOfSnake();
      }
      snakeBitSlidingToNeck?.updatePositionAsSlidingToNeck();
      snakeBitSlidingToRemove?.updatePositionAsSlidingToRemove();
    }
  }
}
