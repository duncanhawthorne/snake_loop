import 'dart:async';

import '../maze/maze.dart';
import 'base_component.dart';

class MovingWallWrapper extends BaseComponent {
  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(maze.physicsFactory.movingWalls());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }
}
