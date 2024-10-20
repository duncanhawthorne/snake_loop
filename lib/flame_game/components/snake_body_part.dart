import 'package:flame/collisions.dart';
import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../pacman_world.dart';
import 'food_pellet.dart';
import 'pellet.dart';
import 'snake_wrapper.dart';

class SnakeBodyBit extends CircleComponent
    with HasWorldReference<PacmanWorld>, IgnoreEvents, CollisionCallbacks {
  SnakeBodyBit({required super.position, required this.snakeWrapper})
      : super(radius: snakeRadius, anchor: Anchor.center, paint: snakePaint);

  SnakeWrapper snakeWrapper;
  bool get isActive => current == CharacterState.active;
  bool get isMid => current == CharacterState.mid;
  bool get isDeactive => current == CharacterState.deactive;

  CharacterState current = CharacterState.active;

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

  void midivate() {
    current = CharacterState.mid;
  }

  late final CircleHitbox _hitbox = CircleHitbox(
    isSolid: true,
    collisionType: CollisionType.passive,
    radius: radius * (1 - hitboxGenerosity),
    position: Vector2.all(radius),
    anchor: Anchor.center,
  );

  @override
  Future<void> onMount() async {
    super.onMount();
    activate();
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    add(_hitbox);
    snakeWrapper.bodyBits.add(this);
  }

  @override
  Future<void> onRemove() async {
    current = CharacterState.deactive;
    snakeWrapper.bodyBits.remove(this);
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

enum CharacterState { active, mid, deactive }

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
    recycledBit.position.setFrom(position);
    recycledBit.snakeWrapper = snakeWrapper;
    recycledBit
        .add(MoveToPositionEffect(position), duration: 0); //FIXME fixes hitbox but shouldn't be necessary
    return recycledBit;
  }
}
