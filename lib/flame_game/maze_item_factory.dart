import 'package:flame/components.dart';

import 'components/wall.dart';
import 'maze_dimensions.dart';
import 'maze_layout.dart';

class MazeItemFactory {
  MazeItemFactory({required this.layout, required this.dimensions});

  final MazeLayout layout;
  final MazeDimensions dimensions;

  List<Component> blockingWalls() {
    final List<Component> result = <Component>[];
    final double scale = dimensions.blockWidth;
    const int width = 7;
    final Vector2 size = Vector2(scale * width, scale * layout.length);
    final Vector2 position = Vector2(
      scale * (layout.lengthHBuffered / 2 + width / 2),
      0,
    );
    result
      ..add(WallRectangleVisual(position: position, size: size))
      ..add(WallRectangleVisual(position: position..x *= -1, size: size));
    return result;
  }

  Iterable<Vector2> miniPelletPositions(bool superPelletsEnabled) sync* {
    final Vector2 center = Vector2.zero();
    for (int i = 0; i < layout.length; i++) {
      for (int j = 0; j < layout.lengthH; j++) {
        if (layout.pelletAt(i, j)) {
          final bool isSuperPellet = layout.pelletIsSuperPellet(i, j);
          if (!isSuperPellet || !superPelletsEnabled) {
            center.setFrom(
              dimensions.volatileVectorFromIJ(i, j, ioffset: 0.5, joffset: 0.5),
            );
            yield center;
          }
        }
      }
    }
  }

  Iterable<Vector2> superPelletPositions() sync* {
    final Vector2 center = Vector2.zero();
    for (int i = 0; i < layout.length; i++) {
      for (int j = 0; j < layout.lengthH; j++) {
        if (layout.pelletAt(i, j) && layout.pelletIsSuperPellet(i, j)) {
          center.setFrom(
            dimensions.volatileVectorFromIJ(i, j, ioffset: 0.5, joffset: 0.5),
          );
          yield center;
        }
      }
    }
  }
}
