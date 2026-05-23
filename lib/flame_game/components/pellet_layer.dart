import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/foundation.dart';

import '../maze/maze.dart';
import '../pacman_game.dart';
import 'mini_pellet.dart';
import 'super_pellet.dart';
import 'wrapper_no_events.dart';

/// Use wrappers to minimise number of components directly in main world
/// Helps due to loops running through all child components
/// Especially on drag events deliverAtPoint
/// Also set IgnoreEvents to speed up deliverAtPoint for all components queried

class PelletWrapper extends WrapperNoEvents
    with HasGameReference<PacmanGame>, Snapshot {
  @override
  final int priority = -2;

  final ValueNotifier<int> pelletsRemainingNotifier = ValueNotifier<int>(0);

  @override
  Future<void> reset() async {
    if (children.isNotEmpty) {
      removeAll(children);
    }
    final bool superPelletsEnabled = game.level.superPelletsEnabled;
    for (Vector2 pos in maze.itemFactory.miniPelletPositions(
      superPelletsEnabled,
    )) {
      add(
        MiniPellet(
          position: pos,
          pelletsRemainingNotifier: pelletsRemainingNotifier,
        ),
      );
    }
    if (superPelletsEnabled) {
      for (Vector2 pos in maze.itemFactory.superPelletPositions()) {
        add(
          SuperPellet(
            position: pos,
            pelletsRemainingNotifier: pelletsRemainingNotifier,
          ),
        );
      }
    }
    clearSnapshot();
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    pelletsRemainingNotifier.addListener(() {
      assert(!isRemoving);
      clearSnapshot();
    });
    await reset();
    renderSnapshot = true;
  }

  @override
  void updateTree(double dt) {
    // no point traversing large list of children as nothing to update
    // so cut short the updateTree here
    //super.updateTree(dt);
  }
}
