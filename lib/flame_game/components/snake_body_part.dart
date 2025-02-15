import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_head.dart';
import 'snake_line_part.dart';
import 'snake_wrapper.dart';

final Vector2 _volatileV2 = Vector2(0, 0);
final Vector2 _hitboxPosition = Vector2.all(snakeRadius);

class SnakeBodyBit extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyBit(
      {required super.position,
      required this.snakeWrapper,
      SnakeBodyBit? oneBack})
      : _oneBack = oneBack,
        super(radius: snakeRadius, anchor: Anchor.center, paint: snakePaint);

  SnakeWrapper snakeWrapper;
  SnakeBodyBit? _oneBack;
  SnakeBodyBit? _oneForward;
  late final SnakeLineBit _backwardLineBit =
      SnakeLineBit(oneForward: this, oneBack: null);
  int numberId = 0;
  bool active = false;

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.inactive,
    radius: radius * (1 - hitboxGenerosity),
    position: _hitboxPosition,
    anchor: Anchor.center,
  );

  bool _landed = false;

  void updatePositionAsSlidingToNeck() {
    if (_landed) {
      return;
    }
    if (snakeWrapper.snakeNeck == null) {
      return;
    }
    final SnakeHead snakeHead = snakeWrapper.snakeHead;
    final SnakeBodyBit snakeNeck = snakeWrapper.snakeNeck!;
    if (snakeHead.position.distanceTo(snakeNeck.position) <
        distanceBetweenSnakeBits) {
      //track
      position = snakeHead.position;
      if (PacmanGame.stepDebug) {
        paint = snakeTextPaint;
      }
    } else {
      //land
      _landed = true;
      position = _volatileV2
        ..setFrom(snakeHead.position)
        ..sub(snakeNeck.position)
        ..scaleTo(distanceBetweenSnakeBits)
        ..add(snakeNeck.position);
      if (PacmanGame.stepDebug) {
        paint = snakePaint;
      }
      snakeWrapper.addToStartOfSnake();
    }
    _backwardLineBit.fixPosition();
  }

  bool _extendMode = false;
  void updatePositionAsSlidingToRemove() {
    if (snakeWrapper.tooFewBits) {
      //add more bits to snake, no action to end of snake
      _extendMode = true;
      return;
    }
    if (_extendMode) {
      //first time in extend mode don't reposition end else end will jump back
      _extendMode = false;
      return;
    }
    if (snakeWrapper.tooManyBits && snakeWrapper.bodyBits.indexOf(this) == 0) {
      position = offscreen;
      removeToSpares();
    } else {
      if (_oneForward != null && snakeWrapper.snakeNeck != null) {
        final double neckDistance = snakeWrapper.snakeHead.position
            .distanceTo(snakeWrapper.snakeNeck!.position);
        position = _volatileV2
          ..setFrom(position)
          ..sub(_oneForward!.position)
          ..scaleTo(max(0.0001, distanceBetweenSnakeBits - neckDistance))
          ..add(_oneForward!.position);
        if (PacmanGame.stepDebug) {
          paint = snakeTextPaint;
        }
      }
    }
    _oneForward?._backwardLineBit.fixPosition();
  }

  bool get _willGetHitBox => numberId % snakeBitsOverlaps == 0;

  void activateHitbox() {
    if (_willGetHitBox) {
      //only done for every n bits
      _hitbox.collisionType = CollisionType.passive;
      _hitbox.debugColor = Colors.red;
    }
  }

  void activate() {
    _landed = false;
    active = true;
    assert(_oneForward == null);
    final List<SnakeBodyBit> bodyBits = snakeWrapper.bodyBits;
    // ignore: cascade_invocations
    bodyBits.add(this);
    if (bodyBits.length == 1) {
      _oneBack = null;
      numberId = 0;
    } else {
      _oneBack = bodyBits[bodyBits.length - 2];
      _oneBack!._oneForward = this;
      numberId = _oneBack!.numberId + 1;
      _backwardLineBit.oneBack = _oneBack!;
    }
    if (_willGetHitBox) {
      add(_hitbox);
    }
    snakeWrapper.spareBodyBits.remove(this);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    parent!.add(_backwardLineBit);
  }

  void _syncRemovalActions() {
    active = false;
    snakeWrapper.bodyBits.remove(this);
    if (PacmanGame.stepDebug) {
      paint = snakeWarningPaint;
    }
    _oneForward?._oneBack = null;
    _backwardLineBit.oneBack = null;
    _hitbox
      ..collisionType = CollisionType.inactive
      ..debugColor = Colors.yellow
      ..removeFromParent();
    _oneForward?._backwardLineBit.fixPosition();
    _oneForward = null;
    _oneBack = null;
  }

  void removeToSpares() {
    _syncRemovalActions();
    snakeWrapper.spareBodyBits.add(this);
    position = offscreen;
  }

  @override
  void removeFromParent() {
    _syncRemovalActions();
    super.removeFromParent();
  }

  @override
  Future<void> onRemove() async {
    _syncRemovalActions();
    super.onRemove();
  }

  @override
  void onCollision(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollision(intersectionPoints, other);
    _onCollideWith(other);
  }

  void _onCollideWith(PositionComponent other) {
    if (other is Pellet) {
      //debug(["snake body bit collide", other]);
      _onCollideWithPellet(other);
    }
  }

  void _onCollideWithPellet(Pellet pellet) {
    if (pellet is Food && snakeWrapper.snakeNeck != this) {
      pellet.position = snakeWrapper.getSafePositionForFood();
      //dont increment score as not captured by head
    }
  }
}
