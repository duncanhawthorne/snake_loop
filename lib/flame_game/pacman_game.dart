import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/src/workarounds.dart';
import 'components/physics_ball.dart';
import 'game_screen.dart';
import 'maze/maze.dart';
import 'mixins/game_dialog_manager.dart';
import 'mixins/game_lifecycle.dart';
import 'mixins/game_playback_manager.dart';
import 'mixins/game_session.dart';
import 'pacman_world.dart';

/// This is the base of the game which is added to the [GameWidget].
///
/// This class defines a few different properties for the game:
///  - That it should have a [FixedResolutionViewport] containing
///  a square of size [kVirtualGameSize]
///  this means that even if you resize the window, the square itself will keep
///  the defined virtual resolution.
///  - That the default world that the camera is looking at should be the
///  [PacmanWorld].
///
/// Note that both of the last are passed in to the super constructor, they
/// could also be set inside of `onLoad` for example.

// flame_forge2d has a maximum allowed speed for physical objects.
// Reducing map size 30x, scaling up gravity 30x, & zooming 30x changes nothing,
// but reduces chance of hitting maximum allowed speed
const double flameGameZoom = 30.0 / spriteVsPhysicsScale;
const double _visualZoomMultiplier = 0.92;
const double kVirtualGameSize = 1700; //determines speed of game

class PacmanGame extends Forge2DGame<PacmanWorld>
    with
        // ignore: always_specify_types
        HasQuadTreeCollisionDetection,
        SingleGameInstance,
        HasTimeScale {
  PacmanGame._({
    required this.level,
    required int mazeId,
    required this.playerProgress,
    required this.audioController,
    required this.appLifecycleStateNotifier,
  }) : super(
         world: PacmanWorld(),
         camera: CameraComponent.withFixedResolution(
           width: kVirtualGameSize,
           height: kVirtualGameSize,
         ),
         zoom: flameGameZoom * _visualZoomMultiplier,
       ) {
    this.mazeId = mazeId;
  }

  factory PacmanGame({
    required GameLevel level,
    required int mazeId,
    required PlayerProgress playerProgress,
    required AudioController audioController,
    required AppLifecycleStateNotifier appLifecycleStateNotifier,
  }) {
    if (_instance == null) {
      _instance = PacmanGame._(
        level: level,
        mazeId: mazeId,
        playerProgress: playerProgress,
        audioController: audioController,
        appLifecycleStateNotifier: appLifecycleStateNotifier,
      );
    } else {
      _instance!
        ..level = level
        ..mazeId = mazeId
        ..reset(firstRun: false, showStartDialog: true);
    }
    return _instance!;
  }

  ///ensures singleton [PacmanGame]
  static PacmanGame? _instance;

  /// What the properties of the level that is played has.
  GameLevel level;

  set mazeId(int id) => maze.mazeId = id;

  int get mazeId => maze.mazeId;

  final AudioController audioController;
  final AppLifecycleStateNotifier appLifecycleStateNotifier;
  final PlayerProgress playerProgress;

  final GameSession session = GameSession();
  final GameLifecycle lifecycle = GameLifecycle();
  late final GamePlaybackManager playback = GamePlaybackManager()..game = this;
  late final GameDialogManager dialogManager = GameDialogManager()..game = this;

  bool get isLive => !paused && isLoaded && isMounted;

  final Random random = Random();

  @override
  Color backgroundColor() => Palette.background.color;

  void play(SfxType type) {
    const bool soundOn = true;
    if (soundOn) {
      audioController.playSfx(type);
    }
  }

  @override
  Future<void> onGameResize(Vector2 size) async {
    camera.viewport = FixedResolutionViewport(
      resolution: _sanitizeScreenSize(size),
    );
    super.onGameResize(size);
  }

  void reset({bool firstRun = false, bool showStartDialog = false}) {
    //audioController.soLoudReset();

    if (!firstRun) {
      assert(world.isLoaded);
      world.reset();
    }
    collisionDetection.broadphase.tree.optimize();
    if (showStartDialog) {
      playback.isPlaybackAppropriate()
          ? playState = PlayState.playbackMode
          : playState = PlayState.levelChooseScreen;
    }
  }

  void resetAndStart() {
    reset();
    start();
  }

  void start() {
    audioController.workaroundiOSSafariAudioOnUserInteraction();
    play(SfxType.startMusic);
    //resumeEngine();
    world.start();
  }

  void _bugFixes() {
    setStatusBarColor(Palette.background.color);
  }

  /// In the [onLoad] method you load different type of assets and set things
  /// that only needs to be set once when the level starts up.
  @override
  Future<void> onLoad() async {
    super.onLoad();
    _bugFixes();
    initializeCollisionDetection(
      mapDimensions: Rect.fromLTWH(
        -maze.dimensions.mazeWidth / 2,
        -maze.dimensions.mazeHeight / 2,
        maze.dimensions.mazeWidth,
        maze.dimensions.mazeHeight,
      ),
    ); //assume maze size won't change
    reset(firstRun: true, showStartDialog: true);
  }

  @override
  Future<void> onRemove() async {
    super.onRemove();
    await audioController.stopAllSounds();
  }

  PlayState _playState = PlayState.playbackMode;

  PlayState get playState => _playState;

  set playState(PlayState s) => _setState(s);

  void _setState(PlayState s) {
    if (_playState == s && s == PlayState.gaming) {
      return;
    }
    _playState = s;
    switch (s) {
      case PlayState.playbackMode:
        playback.enable();
        dialogManager.cleanDialogs();
        overlays.add(GameScreen.beginDialogKey);
      case PlayState.levelChooseScreen:
        playback.disable();
        dialogManager.cleanDialogs();
        overlays.add(GameScreen.startDialogKey);
      case PlayState.gaming:
        playback.disable();
        dialogManager.cleanDialogs();
        start();
    }
  }
}

Vector2 _sanitizeScreenSize(Vector2 size) {
  if (size.x > size.y) {
    return Vector2(kVirtualGameSize * size.x / size.y, kVirtualGameSize);
  } else {
    return Vector2(kVirtualGameSize, kVirtualGameSize * size.y / size.x);
  }
}

enum PlayState { playbackMode, levelChooseScreen, gaming }
