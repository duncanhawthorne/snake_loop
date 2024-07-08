const gameLevels = <GameLevel>[
  (
    number: 1,
    maxAllowedDeaths: 3,
    superPelletsEnabled: true,
    multipleSpawningGhosts: false,
    ghostSpwanTimerLength: -1,
    homingGhosts: false,
  ),
  (
    number: 2,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: false,
    ghostSpwanTimerLength: -1,
    homingGhosts: false,
  ),
  (
    number: 3,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 5,
    homingGhosts: false,
  ),
  (
    number: 4,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 3,
    homingGhosts: false,
  ),
  (
    number: 5,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 2,
    homingGhosts: false,
  ),
  (
    number: 6,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 1,
    homingGhosts: false,
  ),
  (
    number: 7,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 5,
    homingGhosts: true,
  ),
  (
    number: 8,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 3,
    homingGhosts: true,
  ),
  (
    number: 9,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 2,
    homingGhosts: true,
  ),
  (
    number: 10,
    maxAllowedDeaths: 3,
    superPelletsEnabled: false,
    multipleSpawningGhosts: true,
    ghostSpwanTimerLength: 1,
    homingGhosts: true,
  ),
];

typedef GameLevel = ({
  int number,
  int maxAllowedDeaths,
  bool superPelletsEnabled,
  bool multipleSpawningGhosts,
  int ghostSpwanTimerLength,
  bool homingGhosts,
});
