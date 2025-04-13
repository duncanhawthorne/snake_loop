import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/geometry.dart';
import 'package:flutter/material.dart';

import '../pacman_game.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_head.dart';
import 'snake_line_part.dart';
import 'snake_wrapper.dart';

final Vector2 _volatileV2 = Vector2(0, 0);
const double _spriteFactor = 1;

class SnakeBodyBit extends SpriteComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyBit({
    required super.position,
    required this.snakeWrapper,
    SnakeBodyBit? oneBack,
  }) : _oneBack = oneBack,
       super(
         size: Vector2.all(snakeRadius * 2 * _spriteFactor),
         anchor: Anchor.center,
         paint: snakePaint,
       );

  double get radius => size.x / 2 / _spriteFactor;

  SnakeWrapper snakeWrapper;
  SnakeBodyBit? _oneBack;
  SnakeBodyBit? _oneForward;
  late final SnakeLineBit _backwardLineBit = SnakeLineBit(
    oneForward: this,
    oneBack: null,
  );
  int numberId = 0;
  bool active = false;

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.inactive,
    radius: radius * (1 - hitboxGenerosity),
    position: _volatileV2..setAll(size.x / 2),
    anchor: Anchor.center,
  )..debugMode = false;

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
      angle = -atan2(world.downDirection.x, world.downDirection.y) + tau / 2;
      if (PacmanGame.stepDebug) {
        paint = snakeTextPaint;
      }
    } else {
      //land
      _landed = true;
      position =
          _volatileV2
            ..setFrom(snakeHead.position)
            ..sub(snakeNeck.position)
            ..scaleTo(distanceBetweenSnakeBits)
            ..add(snakeNeck.position);
      angle = -atan2(world.downDirection.x, world.downDirection.y) + tau / 2;
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
        final double neckDistance = snakeWrapper.snakeHead.position.distanceTo(
          snakeWrapper.snakeNeck!.position,
        );
        position =
            _volatileV2
              ..setFrom(position)
              ..sub(_oneForward!.position)
              ..scaleTo(max(0, distanceBetweenSnakeBits - neckDistance))
              ..add(_oneForward!.position);
        if (PacmanGame.stepDebug) {
          paint = snakeTextPaint;
        }
      }
    }
    _oneForward?._backwardLineBit.fixPosition();
  }

  bool get _willGetHitBox => numberId % snakeBitsOverlaps == 0;

  void activateHitbox(bool activate) {
    if (activate) {
      if (_willGetHitBox) {
        //only done for every n bits
        _hitbox
          ..debugColor = Colors.red
          ..collisionType = CollisionType.passive;
      }
    } else {
      _hitbox
        ..debugColor = Colors.yellow
        ..collisionType = CollisionType.inactive
        ..removeFromParent();
    }
  }

  void activate() {
    _landed = false;
    active = true;
    assert(_oneForward == null); //can't be anything in front of new bit
    assert(_oneBack == null); //hasn't been set yet
    final List<SnakeBodyBit> bodyBits = snakeWrapper.bodyBits;
    if (bodyBits.isEmpty) {
      //first bit
      _oneBack = null;
      numberId = 0;
    } else {
      _oneBack = bodyBits.last;
      _oneBack!._oneForward = this;
      numberId = _oneBack!.numberId + 1;
    }
    _backwardLineBit.oneBack = _oneBack; //could be null
    bodyBits.add(this);
    if (_willGetHitBox) {
      add(_hitbox); //load now so ready, activate later
      assert(_hitbox.collisionType == CollisionType.inactive);
    }
    snakeWrapper.spareBodyBits.remove(this);
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('body.png');
    angle = -atan2(world.downDirection.x, world.downDirection.y) + tau / 2;
    parent!.add(_backwardLineBit);
  }

  void _deactivate() {
    active = false;
    snakeWrapper.bodyBits.remove(this);
    if (PacmanGame.stepDebug) {
      paint = snakeWarningPaint;
    }
    activateHitbox(false);
    _oneForward?._oneBack = null;
    _oneForward?._backwardLineBit.oneBack = null;
    _oneForward?._backwardLineBit.fixPosition();
    assert(_backwardLineBit.oneBack == null);
    _backwardLineBit.oneBack = null;
    _oneForward = null;
    assert(_oneBack == null);
    _oneBack = null;
  }

  void removeToSpares() {
    _deactivate();
    snakeWrapper.spareBodyBits.add(this);
    position = offscreen;
  }

  @override
  void removeFromParent() {
    _deactivate();
    super.removeFromParent();
  }

  @override
  Future<void> onRemove() async {
    _deactivate();
    super.onRemove();
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
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
