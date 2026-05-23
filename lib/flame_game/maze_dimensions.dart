import 'dart:math';

import 'package:flame/components.dart';

import 'components/physics_ball.dart';
import 'maze_data.dart';
import 'maze_layout.dart';
import 'pacman_game.dart';

class MazeDimensions {
  MazeDimensions({required this.layout}) {
    //items below used every frame so calculate once here
    blockWidth = _blockWidth();
    spriteWidth = _spriteWidth();
    mazeWidth = blockWidth * layout.lengthHBuffered;
    mazeHeight = blockWidth * layout.length;
    spriteSize.setAll(spriteWidth);
    cloneThreshold = mazeWidth / 2 - spriteWidth / 2;
    mazeHalfWidthPhysics = mazeWidth / 2 / spriteVsPhysicsScale;
    mazeHalfHeightPhysics = mazeHeight / 2 / spriteVsPhysicsScale;
    //other items
    ghostStart.setFrom(_volatileVectorOfMazeItem(MazeData.kGhostStart));
    pacmanStart.setFrom(_volatileVectorOfMazeItem(MazeData.kPacmanStart));
    _cage.setFrom(_volatileVectorOfMazeItem(MazeData.kCage));
    //item below used regularly
    _ghostStartForIdMap[0] = _ghostStartForId(0);
    _ghostStartForIdMap[1] = _ghostStartForId(1);
    _ghostStartForIdMap[2] = _ghostStartForId(2);
  }

  final MazeLayout layout;
  static final Vector2 _reusableVector = Vector2.zero();

  final Vector2 ghostStart = Vector2.zero(); //set properly in initializer
  final Vector2 pacmanStart = Vector2.zero(); //set properly in initializer
  final Vector2 _cage = Vector2.zero(); //set properly in initializer
  double mazeWidth = 0; //set properly in initializer
  double mazeHeight = 0; //set properly in initializer
  double blockWidth = 0; //set properly in initializer
  double spriteWidth = 0; //set properly in initializer
  double cloneThreshold = 0; //set properly in initializer
  double mazeHalfWidthPhysics = 0; //set properly in initializer
  double mazeHalfHeightPhysics = 0; //set properly in initializer
  final Vector2 spriteSize = Vector2.zero(); //set properly in initializer
  final Map<int, Vector2> _ghostStartForIdMap =
      <int, Vector2>{}; //set properly in initializer

  double _blockWidth() {
    return kVirtualGameSize /
        flameGameZoom /
        max(layout.lengthHBuffered, layout.length);
  }

  double _spriteWidth() {
    return blockWidth * 2;
  }

  Vector2 volatileVectorFromIJ(
    int icore,
    int jcore, {
    double ioffset = 0,
    double joffset = 0,
  }) {
    final double i = ioffset + icore;
    final double j = joffset + jcore;

    /// using _reusableVector
    /// so we don't have to make new Vector2 every time called
    /// but therefore must instantly consume the output as it may change
    assert(blockWidth != 0); //i.e. not set yet
    _reusableVector.setValues(
      (j + 1 / 2 - layout.lengthH / 2) * blockWidth,
      (i + 1 / 2 - layout.length / 2) * blockWidth,
    );
    return _reusableVector;
  }

  Vector2 _volatileVectorOfMazeItem(String code) {
    final (int i, int j) = layout.ijOfMazeListCode(code);
    return volatileVectorFromIJ(i, j, ioffset: 0.5);
  }

  Vector2 ghostStartForId(int idNum) {
    return _ghostStartForIdMap[idNum % 3]!;
  }

  Vector2 _ghostStartForId(int idNum) {
    assert(ghostStart.x != 0 || ghostStart.y != 0); //i.e. not set yet
    return ghostStart.clone()..x += spriteWidth * (idNum % 3 - 1);
  }

  Vector2 ghostSpawnForId(int idNum) {
    return idNum <= 2 ? ghostStartForId(idNum) : _cage;
  }

  int spriteWidthOnScreen(Vector2 size) {
    return (spriteWidth /
            (kVirtualGameSize / flameGameZoom) *
            min(size.x, size.y))
        .toInt();
  }
}
