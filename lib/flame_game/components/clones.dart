import 'dart:core';

import 'package:flame/components.dart';

import '../maze/maze.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pacman.dart';

/// A visual clone of Pacman used for wrapping around maze edges.
class PacmanClone extends Pacman with Clone {
  PacmanClone({
    required Vector2 super.position,
    required Pacman super.original,
  });
}

/// A visual clone of a ghost used for wrapping around maze edges.
class GhostClone extends Ghost with Clone {
  GhostClone({required super.ghostID, required Ghost super.original});
}

/// Mixin providing logic for visual clones that follow an original character's state
/// with position wrapped around maze edges.
mixin Clone on GameCharacter {
  @override
  // ignore: overridden_fields
  final PhysicsState state = PhysicsState.none;

  /// Syncs the clone's position, angle, and state with the original character,
  /// but mirrors it on the opposite side of the maze.
  void updateCloneFrom(GameCharacter original) {
    assert(isClone);
    position
      ..setFrom(original.position)
      ..x -= maze.dimensions.mazeWidth * position.x.sign; //mirror on other side
    angle = original.angle;
    current = original.current;
  }

  @override
  void update(double dt) {
    assert(isClone); //i.e. no cascade of clones
    assert(original != null);
    assert(!original!.isRemoving);
    assert(original!.isMounted);
    updateCloneFrom(original!);
    super.update(dt); // must call to have sprite animations
  }
}
