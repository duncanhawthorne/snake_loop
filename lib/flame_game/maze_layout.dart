import 'maze.dart';
import 'maze_data.dart';

class MazeLayout {
  MazeLayout(int mazeId, {required bool enableRotationRaceMode}) {
    mazeLayout = _decodeMazeLayout(
      _selectRawLayout(mazeId, enableRotationRaceMode),
    );
  }

  late final List<List<String>> mazeLayout;

  static const int _bufferColumns = 2;

  List<String> _selectRawLayout(int id, bool raceMode) {
    return switch (id) {
      Maze.tutorialMazeId => MazeData.mazeTutorialLayout,
      Maze.defaultMazeId =>
        raceMode ? MazeData.raceTrack : MazeData.mazeP1Layout,
      1 => MazeData.mazeMP4Layout,
      2 => MazeData.mazeMP1Layout,
      _ => throw ArgumentError('Unknown maze ID: $id'),
    };
  }

  int mazeLayoutHorizontalLength() {
    return mazeLayout.isEmpty ? 0 : (mazeLayout[0].length - _bufferColumns);
  }

  int mazeLayoutVerticalLength() {
    return mazeLayout.length;
  }

  bool wallAt(int i, int j) {
    return i >= 0 &&
        i < mazeLayout.length &&
        j >= 0 &&
        j < mazeLayout[i].length &&
        mazeLayout[i][j] == MazeData.kWall;
  }

  bool circleAt(int i, int j) {
    assert(wallAt(i, j));
    return !(wallAt(i - 1, j) && wallAt(i + 1, j) ||
        wallAt(i, j - 1) && wallAt(i, j + 1));
  }

  bool movingWallAt(int i, int j) {
    return i >= 0 &&
        i < mazeLayout.length &&
        j >= 0 &&
        j < mazeLayout[i].length &&
        mazeLayout[i][j] == MazeData.kMovingWall;
  }

  bool _pelletCodeAtCell(int i, int j) {
    final String char = mazeLayout[i][j];
    return char == MazeData.kMiniPellet ||
        char == MazeData.kSuperPellet ||
        char == MazeData.kMovingWall;
  }

  bool pelletAt(int i, int j) {
    return i >= 0 &&
        j >= 0 &&
        i + 1 < mazeLayout.length &&
        j + 1 < mazeLayout[0].length &&
        _pelletCodeAtCell(i, j) &&
        _pelletCodeAtCell(i, j + 1) &&
        _pelletCodeAtCell(i + 1, j) &&
        _pelletCodeAtCell(i + 1, j + 1);
  }
}

List<List<String>> _decodeMazeLayout(List<String> encodedMazeLayout) {
  final List<List<String>> result = <List<String>>[];
  for (final String row in encodedMazeLayout) {
    result.add(row.split(""));
  }
  return result;
}
