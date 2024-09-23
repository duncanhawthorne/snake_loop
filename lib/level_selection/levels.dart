final gameLevels = List.generate(
    16,
    (index) => (
          number: index,
          maxAllowedDeaths: 3,
          superPelletsEnabled: false,
          multipleSpawningGhosts: true,
          ghostSpawnTimerLength: 1,
          homingGhosts: true,
        ));

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts,
  int ghostSpawnTimerLength,
  bool homingGhosts,
});

GameLevel levelSelect(int levelNum) {
  return gameLevels.firstWhere((level) => level.number == levelNum,
      orElse: () =>
          gameLevels.firstWhere((level) => level.number == defaultLevelNum));
}

bool isTutorialLevel(GameLevel level) {
  return level.number == tutorialLevelNum;
}

int maxLevel() {
  return gameLevels.last.number;
}

const defaultLevelNum = 1;
const tutorialLevelNum = 0;
