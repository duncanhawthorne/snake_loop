import 'dart:async';

import '../maze.dart';
import 'wrapper_no_events.dart';

class MovingWallWrapper extends WrapperNoEvents {
  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(maze.factory.mazeMovingWalls());
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }
}
