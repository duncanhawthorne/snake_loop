import '../maze/maze.dart';
import 'clones.dart';
import 'game_character.dart';
import 'ghost.dart';
import 'pacman.dart';
import 'sprite_character.dart';

/// Mixin that manages the lifecycle of visual clones for character wrapping.
mixin CloneManager on SpriteCharacter {
  bool _cloneEverMade = false; //could just test clone is null
  GameCharacter? _clone;

  /// Initializes the character's clone if it hasn't been created yet.
  void _createClone() {
    if (!_cloneEverMade) {
      assert(_clone == null);
      _cloneEverMade = true;
      if (this is Pacman) {
        _clone = PacmanClone(position: position, original: this as Pacman);
      } else if (this is Ghost) {
        _clone = GhostClone(
          ghostID: (this as Ghost).ghostID,
          original: this as Ghost,
        );
      }
    }
  }

  /// Adds or removes the visual clone based on whether the character is near the maze edges.
  void _addRemoveClone() {
    if (isClone) {
      //i.e. no cascade of clones
      return;
    }
    //run every frame
    if (position.x.abs() > maze.dimensions.cloneThreshold) {
      _createClone();
      assert(_clone != null);
      assert(_clone!.isClone);
      if (!_clone!.isMounted) {
        parent?.add(_clone!);
      }
    } else {
      if (_cloneEverMade && _clone!.isMounted) {
        assert(_clone != null);
        _clone?.removeFromParent();
      }
    }
  }

  @override
  void update(double dt) {
    //note, this function is also run for clones
    _addRemoveClone();
    super.update(dt);
  }

  @override
  void removalActions() {
    super.removalActions();
    if (!isClone) {
      _cloneEverMade ? _clone?.removeFromParent() : null;
    }
  }
}
