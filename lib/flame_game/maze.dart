import 'components/lap_angle.dart';
import 'maze_dimensions.dart';
import 'maze_item_factory.dart';
import 'maze_layout.dart';
import 'maze_physics_factory.dart';

final Map<int, String> mazeNames = <int, String>{
  -1: "T",
  0: "A",
  1: "B",
  2: "C",
};

class Maze {
  Maze._({required int mazeId}) {
    setMazeId(mazeId);
  }

  factory Maze({required int mazeId}) {
    assert(_instance == null);
    _instance ??= Maze._(mazeId: mazeId);
    return _instance!;
  }

  /// Ensures singleton [Maze]
  static Maze? _instance;

  static const int tutorialMazeId = -1;
  static const int defaultMazeId = 0;

  int _mazeId = -10; //set properly in initializer

  int get mazeId => _mazeId;

  set mazeId(int i) => setMazeId(i);

  late MazeLayout layout;
  late MazeDimensions dimensions;
  late MazePhysicsFactory factory;
  late MazeItemFactory itemFactory;

  void setMazeId(int id) {
    {
      if (_mazeId == id) {
        return;
      }
      _mazeId = id;

      layout = MazeLayout(
        _mazeId,
        enableRotationRaceMode: enableRotationRaceMode,
      );

      dimensions = MazeDimensions(layout: layout);
      factory = MazePhysicsFactory(layout: layout, dimensions: dimensions);
      itemFactory = MazeItemFactory(layout: layout, dimensions: dimensions);
    }
  }

  bool get isTutorial => isTutorialMaze(mazeId);

  bool get isDefault => mazeId == Maze.defaultMazeId;
}

bool isTutorialMaze(int mazeId) {
  return mazeId == Maze.tutorialMazeId;
}

Maze maze = Maze(mazeId: 0);
