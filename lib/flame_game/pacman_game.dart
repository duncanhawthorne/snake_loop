import 'dart:async' as async;
import 'dart:core';
import 'dart:math';
import 'dart:ui';

import 'package:flame/camera.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_forge2d/flame_forge2d.dart';
import 'package:flutter/foundation.dart';

import '../app_lifecycle/app_lifecycle.dart';
import '../audio/audio_controller.dart';
import '../audio/sounds.dart';
import '../firebase/firebase_saves.dart';
import '../level_selection/levels.dart';
import '../player_progress/player_progress.dart';
import '../style/palette.dart';
import '../utils/src/workarounds.dart';
import 'components/physics_ball.dart';
import 'game_screen.dart';
import 'maze/maze.dart';
import 'mixins/game_overlay_manager.dart';
import 'mixins/game_playback_manager.dart';
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
        GamePlaybackManager,
        GameOverlayManager,
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

  String _userString = "";

  static const int _deathPenaltyMillis = 5000;
  final Timer stopwatch = Timer(double.infinity);

  int get stopwatchMilliSeconds =>
      (stopwatch.current * 1000).toInt() +
      (level.isTutorial
          ? 0
          : min(level.maxAllowedDeaths - 1, numberOfDeathsNotifier.value) *
                _deathPenaltyMillis);

  bool stopwatchStarted = false;
  bool regularItemsStarted = false;

  bool get isLive => !paused && isLoaded && isMounted;

  bool get openingScreenCleared =>
      !(!stopwatchStarted && overlays.isActive(GameScreen.startDialogKey));

  final ValueNotifier<int> numberOfDeathsNotifier = ValueNotifier<int>(0);

  bool get isWonOrLost =>
      ((!kDebugMode || world.pellets.isMounted) &&
          world.pellets.pelletsRemainingNotifier.value <= 0) ||
      numberOfDeathsNotifier.value >= level.maxAllowedDeaths;

  final Random random = Random();

  VoidCallback? _lifecycleListenerRef;
  VoidCallback? _deathListenerRef;
  VoidCallback? _pelletListenerRef;

  int framesRendered = 0;

  async.Timer? _activityCheckTimer;

  @override
  Color backgroundColor() => Palette.background.color;

  Map<String, Object> _getCurrentGameState() {
    final Map<String, Object> gameStateTmp = <String, Object>{};
    gameStateTmp["userString"] = _userString;
    gameStateTmp["levelNum"] = level.number;
    gameStateTmp["levelCompleteTime"] = stopwatchMilliSeconds;
    gameStateTmp["dateTime"] = DateTime.now().millisecondsSinceEpoch;
    gameStateTmp["mazeId"] = maze.mazeId;
    return gameStateTmp;
  }

  void play(SfxType type) {
    const bool soundOn = true;
    if (soundOn) {
      audioController.playSfx(type);
    }
  }

  void pauseGame() {
    pause(); //timeScale = 0;
    pauseEngine();
    regularItemsStarted = false; //so restart things next time
    //stopwatch.pause(); //shouldn't be necessary given timeScale = 0
  }

  void resumeGame() {
    if (paused) {
      regularItemsStarted = false; //so restart things next time
      audioController.workaroundiOSSafariAudioOnUserInteraction();
      resume(); //timeScale = 1.0;
      resumeEngine();
    }
  }

  void startRegularItems() {
    if (!regularItemsStarted) {
      audioController.workaroundiOSSafariAudioOnUserInteraction();
      regularItemsStarted = true;
      stopwatchStarted = true; //once per reset
      stopwatch.resume();
      world.ghosts
        ..addSpawner()
        ..ghostSiren.startSirenVolumeUpdaterTimer();
    }
  }

  void stopRegularItems() {
    regularItemsStarted = false;
    stopwatch.pause();
    world.ghosts
      ..removeSpawner()
      ..ghostSiren.cancelSirenVolumeUpdaterTimer();
  }

  void _lifecycleChangeListener() {
    _lifecycleListenerRef = () {
      if (appLifecycleStateNotifier.value == AppLifecycleState.hidden) {
        assert(!isRemoving);
        pauseGame();
      }
    };
    appLifecycleStateNotifier.addListener(_lifecycleListenerRef!);
  }

  void _winOrLoseGameListener() {
    assert(!stopwatchStarted); //so no instant trigger of listeners
    _deathListenerRef = () {
      if (numberOfDeathsNotifier.value >= level.maxAllowedDeaths &&
          stopwatchStarted &&
          !playbackMode) {
        assert(!isRemoving);
        assert(isWonOrLost);
        stopRegularItems();
        _handleLoseGame();
      }
    };
    _pelletListenerRef = () {
      if (world.pellets.pelletsRemainingNotifier.value <= 0 &&
          stopwatchStarted &&
          !playbackMode) {
        assert(!isRemoving);
        assert(isWonOrLost);
        stopRegularItems();
        _handleWinGame();
      }
    };
    numberOfDeathsNotifier.addListener(_deathListenerRef!);
    world.pellets.pelletsRemainingNotifier.addListener(_pelletListenerRef!);
  }

  void _handleWinGame() {
    assert(!isRemoving);
    assert(isWonOrLost);
    assert(!stopwatch.isRunning());
    assert(stopwatchStarted);
    if (world.pellets.pelletsRemainingNotifier.value <= 0) {
      play(SfxType.endMusic);
      world.ghosts.resetAfterGameWin();
      const int minRecordableWinTimeMillis = 10 * 1000;
      if (stopwatchMilliSeconds > minRecordableWinTimeMillis &&
          !level.isTutorial) {
        fBase.firebasePushSingleScore(_userString, _getCurrentGameState());
      }
      playerProgress.saveLevelComplete(_getCurrentGameState());
      cleanDialogs();
      overlays.add(GameScreen.wonDialogKey);
    }
  }

  void _handleLoseGame() {
    assert(!isRemoving);
    assert(isWonOrLost);
    assert(stopwatchStarted);
    audioController.stopAllSounds();
    cleanDialogs();
    overlays.add(GameScreen.loseDialogKey);
  }

  void pauseEngineIfNoActivity() {
    resumeEngine(); //for any catch up animation, if not already resumed
    framesRendered = 0;
    _activityCheckTimer?.cancel(); // Kill any preexisting active loops
    // If all characters at starting position and nothing happening,
    // pause engine to save resources and avoid unnecessary animation
    // check every 10ms, but only pause if nothing happening and still at starting position
    // if something is happening, or not at starting position, then cancel timer and don't pause
    _activityCheckTimer = async.Timer.periodic(
      const Duration(milliseconds: 10),
      (async.Timer timer) {
        if (paused) {
          //already paused, no further action required, just cancel timer
          timer.cancel();
        } else if (playbackMode) {
          //want to continue playback in playbackMode
          timer.cancel();
        } else if (stopwatch.isRunning()) {
          //some game activity has happened, no need to pause, just cancel timer
          timer.cancel();
        } else if (!world.isMounted || !world.ghosts.ghostsLoaded) {
          //core components haven't loaded yet, so wait before start frame count
          framesRendered = 0;
        } else if (framesRendered <= 5) {
          //core components loaded, but not yet had 5 good safety frame
        } else {
          //everything loaded and rendered, and still no game activity
          pauseEngine();
          timer.cancel();
          if (_activityCheckTimer == timer) _activityCheckTimer = null;
        }
      },
    );
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
    resetPlayback(level);
    pauseEngineIfNoActivity();
    _userString = _getRandomString(random, 15);
    cleanDialogs();
    if (showStartDialog) {
      playbackMode
          ? overlays.add(GameScreen.beginDialogKey)
          : overlays.add(GameScreen.startDialogKey);
    }
    stopRegularItems(); //duplicates other items, belt and braces only
    stopwatch
      ..pause()
      ..reset();
    stopwatchStarted = false;
    if (!firstRun) {
      assert(world.isLoaded);
      world.reset();
    }
    collisionDetection.broadphase.tree.optimize();
  }

  void resetAndStart() {
    reset();
    start();
  }

  void start() {
    audioController.workaroundiOSSafariAudioOnUserInteraction();
    play(SfxType.startMusic);
    //resumeEngine();
    pauseEngineIfNoActivity();
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
    _winOrLoseGameListener(); //isn't disposed so run once, not on start()
    _lifecycleChangeListener(); //isn't disposed so run once, not on start()
  }

  @override
  void update(double dt) {
    stopwatch.update(dt * timeScale); //stops stopwatch when timeScale = 0
    framesRendered++;
    playbackAngles();
    super.update(dt);
  }

  @override
  Future<void> onRemove() async {
    cleanDialogs();
    _activityCheckTimer?.cancel();
    _activityCheckTimer = null;
    if (_lifecycleListenerRef != null) {
      appLifecycleStateNotifier.removeListener(_lifecycleListenerRef!);
    }
    if (_deathListenerRef != null) {
      numberOfDeathsNotifier.removeListener(_deathListenerRef!);
    }
    if (_pelletListenerRef != null) {
      world.pellets.pelletsRemainingNotifier.removeListener(
        _pelletListenerRef!,
      );
    }
    numberOfDeathsNotifier.dispose();
    super.onRemove();
    await audioController.stopAllSounds();
  }
}

Vector2 _sanitizeScreenSize(Vector2 size) {
  if (size.x > size.y) {
    return Vector2(kVirtualGameSize * size.x / size.y, kVirtualGameSize);
  } else {
    return Vector2(kVirtualGameSize, kVirtualGameSize * size.y / size.x);
  }
}

const String _chars =
    'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

String _getRandomString(Random random, int length) {
  final List<int> charCodes = List<int>.generate(
    length,
    (_) => _chars.codeUnitAt(random.nextInt(_chars.length)),
    growable: false,
  );
  return String.fromCharCodes(charCodes);
}
