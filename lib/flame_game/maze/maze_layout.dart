import 'maze.dart';
import 'maze_data.dart';

class MazeLayout {
  MazeLayout(int mazeId, {required bool enableRotationRaceMode}) {
    _layout = _decodeMazeLayout(
      _selectRawLayout(mazeId, enableRotationRaceMode),
    );
  }

  late final List<List<String>> _layout;

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

  int get lengthH => _layout.isEmpty ? 0 : (_layout[0].length);

  int get lengthHBuffered =>
      _layout.isEmpty ? 0 : (_layout[0].length - _bufferColumns);

  int get length => _layout.length;

  (int, int) ijOfMazeListCode(String code) {
    for (int i = 0; i < _layout.length; i++) {
      for (int j = 0; j < _layout[i].length; j++) {
        if (_layout[i][j] == code) {
          return (i, j);
        }
      }
    }
    throw 'Missing maze code $code';
  }

  bool wallAt(int i, int j) {
    return i >= 0 &&
        i < _layout.length &&
        j >= 0 &&
        j < _layout[i].length &&
        _layout[i][j] == MazeData.kWall;
  }

  bool circleAt(int i, int j) {
    assert(wallAt(i, j));
    return !(wallAt(i - 1, j) && wallAt(i + 1, j) ||
        wallAt(i, j - 1) && wallAt(i, j + 1));
  }

  bool movingWallAt(int i, int j) {
    return i >= 0 &&
        i < _layout.length &&
        j >= 0 &&
        j < _layout[i].length &&
        _layout[i][j] == MazeData.kMovingWall;
  }

  bool _pelletCodeAtCell(int i, int j) {
    final String char = _layout[i][j];
    return char == MazeData.kMiniPellet ||
        char == MazeData.kSuperPellet ||
        char == MazeData.kMovingWall;
  }

  bool pelletAt(int i, int j) {
    return i >= 0 &&
        j >= 0 &&
        i + 1 < _layout.length &&
        j + 1 < _layout[0].length &&
        _pelletCodeAtCell(i, j) &&
        _pelletCodeAtCell(i, j + 1) &&
        _pelletCodeAtCell(i + 1, j) &&
        _pelletCodeAtCell(i + 1, j + 1);
  }

  bool pelletIsSuperPellet(int i, int j) {
    assert(pelletAt(i, j));
    return _layout[i][j] == MazeData.kSuperPellet;
  }
}

List<List<String>> _decodeMazeLayout(List<String> encodedMazeLayout) {
  final List<List<String>> result = <List<String>>[];
  for (final String row in encodedMazeLayout) {
    result.add(row.split(""));
  }
  return result;
}
