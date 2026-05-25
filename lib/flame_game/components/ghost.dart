import 'package:flame/components.dart';

import '../effects/move_to_effect.dart';
import '../effects/remove_effects.dart';
import '../effects/rotate_effect.dart';
import '../maze/maze.dart';
import 'game_character.dart';
import 'sprite_character.dart';

const Map<int, String> _ghostSpritePaths = <int, String>{
  0: 'ghost1.png',
  1: 'ghost3.png',
  2: 'ghost2.png',
};

final Map<int, Map<CharacterState, SpriteAnimation>>
_ghostSpriteAnimationCache = <int, Map<CharacterState, SpriteAnimation>>{};

class Ghost extends GameCharacter {
  Ghost({required this.ghostID, super.original})
    : super(
        position: maze.dimensions.ghostSpawnForId(ghostID),
        velocity: Vector2.zero(),
        radius: playerSize,
      );

  final int ghostID;

  bool get _shouldFlyingSpawn => ghostID >= 3;

  @override
  Future<Map<CharacterState, SpriteAnimation>> getAnimations([
    int size = 1,
  ]) async {
    final int ghostIconNumber = game.level.numStartingGhosts == 1
        ? 0
        : ghostID % 3;
    if (!_ghostSpriteAnimationCache.containsKey(ghostIconNumber)) {
      final List<Sprite> sprites = await Future.wait(<Future<Sprite>>[
        game.loadSprite(_ghostSpritePaths[ghostIconNumber]!),
        game.loadSprite('ghostscared1.png'),
        game.loadSprite('ghostscared2.png'),
        game.loadSprite('eyes.png'),
      ]);

      _ghostSpriteAnimationCache[ghostIconNumber] =
          <CharacterState, SpriteAnimation>{
            CharacterState.normal: SpriteAnimation.spriteList(<Sprite>[
              sprites[0],
            ], stepTime: double.infinity),
            CharacterState.scared: SpriteAnimation.spriteList(<Sprite>[
              sprites[1],
            ], stepTime: double.infinity),
            CharacterState.scaredIsh: SpriteAnimation.spriteList(<Sprite>[
              sprites[1],
              sprites[2],
            ], stepTime: 0.1),
            CharacterState.dead: SpriteAnimation.spriteList(<Sprite>[
              sprites[3],
            ], stepTime: double.infinity),
            CharacterState.spawning: SpriteAnimation.spriteList(<Sprite>[
              sprites[3],
            ], stepTime: double.infinity),
          };
    }
    return _ghostSpriteAnimationCache[ghostIconNumber]!;
  }

  void setScared() {
    if (game.session.isWonOrLost) {
      return;
    }
    if (current != CharacterState.dead && current != CharacterState.spawning) {
      // if dead, need to continue dead animation without physics applying,
      // then get sequenced to scared via standard sequence code
      current = CharacterState.scared;
    }
  }

  void setScaredToScaredIsh() {
    if (game.session.isWonOrLost) {
      return;
    }
    if (current == CharacterState.scared) {
      current = CharacterState.scaredIsh;
    }
  }

  void setScaredIshToNormal() {
    if (game.session.isWonOrLost) {
      return;
    }
    if (current == CharacterState.scaredIsh) {
      current = CharacterState.normal;
    }
  }

  void setDead() {
    if (game.session.isWonOrLost) {
      return;
    }
    current = CharacterState.dead; //stops further interactions
    if (game.level.multipleSpawningGhosts) {
      removeFromParent();
    } else {
      setPhysicsState(PhysicsState.none);
      add(
        MoveToPositionEffect(
          maze.dimensions.ghostStart,
          onComplete: () {
            setPositionStillActiveCurrentPosition();
            current = world.ghosts.current;
          },
        ),
      );
      resetSlideAngle(this);
    }
  }

  void _setSpawning() {
    if (game.session.isWonOrLost) {
      return;
    }
    current = CharacterState.spawning; //stops further interactions
    setPhysicsState(PhysicsState.none);
    add(
      MoveToPositionEffect(
        game.level.homingGhosts
            ? world.pacmans.ghostHomingTarget
            : maze.dimensions.ghostStart,
        onComplete: () {
          setPositionStillActiveCurrentPosition();
          current = world.ghosts.current;
        },
      ),
    );
  }

  void resetSlideAfterPacmanDeath() {
    current = CharacterState.normal;
    removeEffects(this);
    setPhysicsState(PhysicsState.none);
    add(
      MoveToPositionEffect(
        maze.dimensions.ghostStartForId(ghostID),
        onComplete: () => <void>{
          //initaliseFromOwnerAndSetDynamic()
          //Calling initaliseFromOwnerAndSetDynamic here creates a crash
          //also would be a race condition
        },
      ),
    );
    resetSlideAngle(this);
  }

  void resetInstantAfterPacmanDeath() {
    removeEffects(this);
    current = CharacterState.normal;
    setPositionStillActive(maze.dimensions.ghostStartForId(ghostID));
    angle = 0;
  }

  @override
  Future<void> onLoad() async {
    if (!isClone) {
      if (_shouldFlyingSpawn) {
        setPhysicsState(PhysicsState.none);
      } else {
        setPhysicsState(PhysicsState.full, starting: true);
      }
    }
    await super.onLoad();
    if (!isClone) {
      world.ghosts.ghostList.add(this);
      current = world.ghosts.current;
      if (_shouldFlyingSpawn) {
        _setSpawning();
      }
    }
    animations = await getAnimations(); //load for clone too
  }

  @override
  void removalActions() {
    if (!isClone) {
      world.ghosts.ghostList.remove(this);
    }
    super.removalActions();
  }
}
