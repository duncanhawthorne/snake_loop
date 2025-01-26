import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../maze.dart';

const double _lubricationScaleFactor = 0.99;
const bool _kVerticalPortalsEnabled = false;
final Vector2 _volatileInstantConsumeVector2 =
    Vector2.zero(); //shared across all balls

// ignore: always_specify_types
class PhysicsBall extends BodyComponent with IgnoreEvents {
  PhysicsBall({
    required Vector2 position,
  }) : super(
            fixtureDefs: <FixtureDef>[
              FixtureDef(
                CircleShape(
                    radius: maze.spriteWidth / 2 * _lubricationScaleFactor),
              ),
            ],
            bodyDef: BodyDef(
              position: position,
              type: BodyType.dynamic,
              fixedRotation: true,
            ));

  @override
  // ignore: overridden_fields
  final bool renderBody = false;

  bool _subConnectedBall = true;

  set velocity(Vector2 vel) => body.linearVelocity.setFrom(vel);

  set position(Vector2 pos) => _setPositionNow(pos);

  bool get _outsideMazeBounds =>
      position.x.abs() > maze.mazeHalfWidth ||
      (_kVerticalPortalsEnabled && position.y.abs() > maze.mazeHalfHeight);

  void _setPositionNow(Vector2 pos) {
    body.setTransform(pos, 0);
  }

  void setDynamic() {
    body
      ..setType(BodyType.dynamic)
      ..setActive(true);
    _subConnectedBall = true;
  }

  void setStatic() {
    if (isMounted && body.isActive) {
      // avoid crashes if body not yet initialised
      // Probably about to remove ball anyway
      body
        ..setType(BodyType.static)
        ..setActive(false);
    }
    _subConnectedBall = false;
  }

  Vector2 _teleportedPosition() {
    _volatileInstantConsumeVector2.setValues(
        _smallMod(position.x, maze.mazeWidth),
        !_kVerticalPortalsEnabled
            ? position.y
            : _smallMod(position.y, maze.mazeHeight));
    return _volatileInstantConsumeVector2;
  }

  void _moveThroughPipePortal() {
    if (_subConnectedBall && _outsideMazeBounds) {
      position = _teleportedPosition();
    }
  }

  @override
  void update(double dt) {
    _moveThroughPipePortal();
    super.update(dt);
  }
}

double _smallMod(double position, double mod) {
  //produces number between -mod / 2 and +mod / 2
  position = position % mod;
  return position > mod / 2 ? position - mod : position;
}
