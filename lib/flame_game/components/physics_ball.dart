import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../maze.dart';

const _useForgePhysicsBallRotation = false;
const _instantSetPosition = true;

class PhysicsBall extends BodyComponent with IgnoreEvents {
  PhysicsBall({
    required Vector2 position,
    double? radius,
  }) : super(
            fixtureDefs: [
              FixtureDef(
                CircleShape()
                  ..radius = radius ?? maze.spriteWidth / 2 * 0.99, //0.95
                restitution: 0.0,
                friction: _useForgePhysicsBallRotation ? 1 : 0,
                userData: PhysicsBall,
              ),
            ],
            bodyDef: BodyDef(
              angularDamping: _useForgePhysicsBallRotation ? 0.1 : 0.1,
              position: position,
              type: BodyType.dynamic,
              userData: PhysicsBall,
            ));

  @override
  // ignore: overridden_fields
  final renderBody = false;

  double get speed => body.linearVelocity.length;

  set velocity(Vector2 vel) => body.linearVelocity.setFrom(vel);

  set position(Vector2 pos) =>
      {_instantSetPosition ? _setPositionNow(pos) : _setPositionNextFrame(pos)};

  final Vector2 _oneTimeManualPosition = Vector2(0, 0);
  bool _oneTimeManualPositionSet = false;

  void _setPositionNextFrame(Vector2 pos) {
    assert(!_instantSetPosition);
    _oneTimeManualPosition.setFrom(pos);
    _oneTimeManualPositionSet = true;
  }

  void _setPositionNow(Vector2 pos) {
    body.setTransform(pos, 0); //realCharacter.angle
  }

  bool _subConnectedBall = true;

  void setDynamic() {
    body.setType(BodyType.dynamic);
    body.setActive(true);
    _subConnectedBall = true;
  }

  void setStatic() {
    body.setType(BodyType.static);
    body.setActive(false);
    _subConnectedBall = false;
  }

  void _moveThroughPipePortal() {
    if (_subConnectedBall) {
      if (position.x.abs() > maze.mazeWidth / 2 ||
          position.y.abs() > maze.mazeHeight / 2) {
        position = Vector2(_mod(position.x, maze.mazeWidth),
            _mod(position.y, maze.mazeHeight));
      }
    }
  }

  @override
  void update(double dt) {
    _moveThroughPipePortal();
    if (!_instantSetPosition && _oneTimeManualPositionSet) {
      _setPositionNow(_oneTimeManualPosition);
      _oneTimeManualPositionSet = false;
    }
    super.update(dt);
  }
}

double _mod(double position, double mod) {
  position = position % mod;
  return position > mod / 2 ? position - mod : position;
}
