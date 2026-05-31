import 'dart:async';

import 'package:flame/components.dart';

import '../maze/maze.dart';
import '../pacman_game.dart';
import 'base_component.dart';

/// A container component for static visual boundaries at the edges of the maze.
class BlockingBarWrapper extends BaseComponent
    with HasGameReference<PacmanGame>, Snapshot {
  @override
  final int priority = 1000;
  int _mazeIdLast = -100;

  @override
  Future<void> reset() async {
    if (game.mazeId == _mazeIdLast) {
      return;
    }
    _mazeIdLast = game.mazeId;
    if (children.isNotEmpty) {
      removeAll(children);
    }
    await addAll(maze.itemFactory.blockingWalls());
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    await reset();
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
