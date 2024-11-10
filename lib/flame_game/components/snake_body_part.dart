import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_head.dart';
import 'snake_line_part.dart';
import 'snake_wrapper.dart';

class SnakeBodyBit extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyBit(
      {required super.position, required this.snakeWrapper, this.oneBack})
      : super(radius: snakeRadius, anchor: Anchor.center, paint: snakePaint);

  SnakeWrapper snakeWrapper;
  bool get isActive => current == CharacterState.active;
  bool get isDeactive => current == CharacterState.deactive;
  SnakeBodyBit? oneBack;
  SnakeLineBit? forwardLineBit;

  CharacterState _current = CharacterState.slidingToAddToNeck;
  CharacterState get current => _current;
  set current(CharacterState x) => <void>{
        //debug(x),
        _current = x
      };

  void slideTo(Vector2 targetPosition, {Function()? onComplete}) {
    removeEffects(this);
    add(MoveToPositionEffect(targetPosition,
        duration: distanceBetweenSnakeBits / world.direction.length,
        onComplete: onComplete));
  }

  void instantMoveTo(Vector2 targetPosition) {
    removeEffects(this);
    position = targetPosition;
  }

  void activate() {
    current = CharacterState.active;
    //move it to the last position in bodyBits so order is right for activeBits
    snakeWrapper.bodyBits.remove(this);
    snakeWrapper.bodyBits.add(this);
  }

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.inactive,
    radius: radius * (1 - hitboxGenerosity),
    position: Vector2.all(radius),
    anchor: Anchor.center,
  );

  @override
  Future<void> onMount() async {
    super.onMount();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_hitbox);
    if (oneBack != null) {
      forwardLineBit = SnakeLineBit(oneForward: this, oneBack: oneBack!);
      parent!.add(forwardLineBit!);
    }
    if (!snakeWrapper.bodyBits.contains(this)) {
      snakeWrapper.bodyBits.add(this);
    }
  }

  void becomeNeck() {
    activate();
    snakeWrapper
      ..snakeNeck = this
      ..neckSlideInProgress = false;
    _hitbox.collisionType = CollisionType.passive;
  }

  void fixLineBits() {
    forwardLineBit?.fixPosition();
    oneBack?.forwardLineBit?.fixPosition();
  }

  void updatePositionAsNeck() {
    if (current == CharacterState.slidingToAddToNeck) {
      assert(snakeWrapper.snakeNeck != null);
      final Vector2 vsPosition =
          snakeWrapper.snakeNeck?.position ?? Vector2(0, 0);
      final SnakeHead snakeHead = snakeWrapper.snakeHead;
      if (snakeHead.position.distanceTo(vsPosition) <
          distanceBetweenSnakeBits) {
        //track
        position = snakeHead.position;
      } else {
        //land
        final Vector2 targetPositionForNewSnakeBit = vsPosition +
            (snakeHead.position - vsPosition).normalized() *
                distanceBetweenSnakeBits;
        position = targetPositionForNewSnakeBit;
        becomeNeck();
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    updatePositionAsNeck();
    fixLineBits();
  }

  @override
  Future<void> onRemove() async {
    current = CharacterState.deactive;
    snakeWrapper.bodyBits.remove(this);
    forwardLineBit?.oneForward.oneBack = null; //to help garbage collector
    oneBack = null; //to help garbage collector
    forwardLineBit = null; //to help garbage collector
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

enum CharacterState { active, slidingToRemove, slidingToAddToNeck, deactive }

final List<SnakeBodyBit> _allBits = <SnakeBodyBit>[];
Iterable<SnakeBodyBit> get _spareBits =>
    _allBits.where((SnakeBodyBit item) => item.isDeactive); //!item.isActive

// ignore: non_constant_identifier_names
SnakeBodyBit RecycledSnakeBodyBit(
    {required Vector2 position, required SnakeWrapper snakeWrapper}) {
  if (_spareBits.isEmpty) {
    final SnakeBodyBit newBit =
        SnakeBodyBit(position: position, snakeWrapper: snakeWrapper);
    _allBits.add(newBit);
    return newBit;
  } else {
    final SnakeBodyBit recycledBit = _spareBits.first;
    // ignore: cascade_invocations
    recycledBit.activate(); // isActive = true;
    assert(_spareBits.isEmpty || _spareBits.first != recycledBit);
    recycledBit
      ..position.setFrom(position)
      ..snakeWrapper = snakeWrapper
      ..add(MoveToPositionEffect(position,
          duration: 0)); //FIXME fixes hitbox but shouldn't be necessary
    return recycledBit;
  }
}
