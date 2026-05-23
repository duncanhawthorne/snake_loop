import 'package:flame/components.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../components/physics_ball.dart';
import '../components/wall.dart';
import '../components/wall_dynamic.dart';
import 'maze_dimensions.dart';
import 'maze_layout.dart';

class MazePhysicsFactory {
  MazePhysicsFactory({required this.layout, required this.dimensions});

  final MazeLayout layout;
  final MazeDimensions dimensions;

  static const double _mazeInnerWallWidthFactor = 0.7;
  static const double _pixelationBuffer = 0.03;
  static const double _lubricationScaleFactor = 0.98;

  static final Vector2 _reusableVector = Vector2.zero();

  FixtureDef _fixtureDefBlock({
    required Vector2 position,
    required double width,
    required double height,
    double density = 1,
  }) {
    return FixtureDef(
      friction: openSpaceMovement ? 1 : 0,
      restitution: openSpaceMovement ? 0.4 : 0,
      PolygonShape()
        ..setAsBox(
          width / 2 / spriteVsPhysicsScale,
          height / 2 / spriteVsPhysicsScale,
          _reusableVector
            ..setFrom(position)
            ..scale(1 / spriteVsPhysicsScale),
          0,
        ),
      density: density,
    );
  }

  bool _topLeftOfBigBlock(int i, int j, {bool moving = false}) {
    final bool Function(int i, int j) localWallAt = moving
        ? layout.movingWallAt
        : layout.wallAt;
    assert(localWallAt(i, j));
    return (!localWallAt(i - 1, j) || !localWallAt(i - 1, j + 1)) &&
        (!localWallAt(i, j - 1) || !localWallAt(i + 1, j - 1)) &&
        !localWallAt(i - 1, j - 1) &&
        localWallAt(i + 1, j) &&
        localWallAt(i, j + 1) &&
        localWallAt(i + 1, j + 1);
  }

  int _bigBlockWidth(int i,
      int j, {
        bool singleHeight = true,
        bool moving = false,
      }) {
    final bool Function(int i, int j) localWallAt = moving
        ? layout.movingWallAt
        : layout.wallAt;
    assert(localWallAt(i, j));
    int k = 0;
    while (j + k < layout.lengthH &&
        (singleHeight || localWallAt(i + 1, j + k + 1)) &&
        localWallAt(i, j + k + 1)) {
      k++;
    }
    return k;
  }

  int _bigBlockHeight(int i,
      int j, {
        bool singleWidth = true,
        bool moving = false,
      }) {
    final bool Function(int i, int j) localWallAt = moving
        ? layout.movingWallAt
        : layout.wallAt;
    assert(localWallAt(i, j));
    int l = 0;
    while (i + l < layout.length &&
        (singleWidth || localWallAt(i + l + 1, j + 1)) &&
        localWallAt(i + l + 1, j)) {
      l++;
    }
    return l;
  }

  FixtureDef _fixtureCircle({
    required Vector2 position,
    required double radius,
  }) {
    return FixtureDef(
      CircleShape(
        radius: radius / spriteVsPhysicsScale,
        position: _reusableVector
          ..setFrom(position)
          ..scale(1 / spriteVsPhysicsScale),
      ),
    );
  }

  List<Component> walls({
    bool includeGround = true,
    bool includeVisualWalls = true,
  }) {
    final List<FixtureDef> fixtureDefs = <FixtureDef>[];
    final List<Component> result = <Component>[];
    final double scale = dimensions.blockWidth;
    final Vector2 center = Vector2.zero();
    final Vector2 bigBlockCenter = Vector2.zero();
    final Vector2 bigBlockSize = Vector2.zero();
    for (int i = 0; i < layout.length; i++) {
      for (int j = 0; j < layout.lengthH; j++) {
        center.setFrom(dimensions.volatileVectorFromIJ(i, j));
        if (layout.wallAt(i, j)) {
          if (layout.circleAt(i, j)) {
            fixtureDefs.add(
              _fixtureCircle(position: center, radius: scale / 2),
            );
            result.add(
              WallCircleVisual(
                position: center,
                radius: scale / 2 * _mazeInnerWallWidthFactor,
              ),
            );
          }
          if (!layout.wallAt(i, j - 1)) {
            final int width = _bigBlockWidth(i, j);
            if (width > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2;
              bigBlockSize.setValues(
                scale * (width + _pixelationBuffer),
                scale * _mazeInnerWallWidthFactor,
              );
              fixtureDefs.add(
                _fixtureDefBlock(
                  position: bigBlockCenter,
                  width: scale * (width + _pixelationBuffer),
                  height: scale,
                ),
              );
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
          if (!layout.wallAt(i - 1, j)) {
            final int height = _bigBlockHeight(i, j);
            if (height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..y += scale * height / 2;
              bigBlockSize.setValues(
                scale * _mazeInnerWallWidthFactor,
                scale * (height + _pixelationBuffer),
              );
              fixtureDefs.add(
                _fixtureDefBlock(
                  position: bigBlockCenter,
                  width: scale,
                  height: scale * (height + _pixelationBuffer),
                ),
              );
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
          if (_topLeftOfBigBlock(i, j)) {
            final int width = _bigBlockWidth(i, j, singleHeight: false);
            final int height = _bigBlockHeight(i, j, singleWidth: false);
            if (width > 0 && height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2
                ..y += scale * height / 2;
              bigBlockSize.setValues(scale * width, scale * height);
              result.add(
                WallRectangleVisual(
                  position: bigBlockCenter,
                  size: bigBlockSize,
                ),
              );
            }
          }
        }
      }
    }
    if (!includeVisualWalls) {
      result.clear();
    }
    if (includeGround) {
      result.add(WallGround(fixtureDefs: fixtureDefs));
    }
    return result;
  }

  List<Component> movingWalls({
    bool includeGround = true,
    bool includeVisualWalls = true,
  }) {
    final List<Component> result = <Component>[];
    final double scale = dimensions.blockWidth;
    final Vector2 center = Vector2.zero();
    final Vector2 bigBlockCenter = Vector2.zero();
    final Vector2 bigBlockCenterPhysics = Vector2.zero();
    for (int i = 0; i < layout.length; i++) {
      for (int j = 0; j < layout.lengthH; j++) {
        center.setFrom(dimensions.volatileVectorFromIJ(i, j));
        if (layout.movingWallAt(i, j)) {
          if (_topLeftOfBigBlock(i, j, moving: true)) {
            final int width = _bigBlockWidth(i, j, moving: true);
            final int height = _bigBlockHeight(i, j, moving: true);
            if (width > 0 && height > 0) {
              bigBlockCenter
                ..setFrom(center)
                ..x += scale * width / 2
                ..y += scale * height / 2;
              result.add(
                (WallDynamic(
                  position: bigBlockCenterPhysics,
                  fixtureDefs: <FixtureDef>[
                    _fixtureDefBlock(
                      position: Vector2(0, 0),
                      width: scale * (width + 1) * _lubricationScaleFactor,
                      height: scale * (height + 1) * _lubricationScaleFactor,
                      density: 10,
                    ),
                  ],
                  //bigBlockCenter, //
                )),
              );
            }
          }
        }
      }
    }
    return result;
  }
}
