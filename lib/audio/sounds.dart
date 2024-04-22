List<String> soundTypeToFilename(SfxType type) {
  switch (type) {
    case SfxType.ghostsScared:
      return const [
        'ghosts_runaway.mp3',
      ];
    case SfxType.doubleJump:
      return const [
        'double_jump1.mp3',
      ];
    case SfxType.eatGhost:
      return const [
        'eat_ghost.mp3'
        //'hit2.mp3',
      ];
    case SfxType.pacmanDeath:
      return const [
        'pacman_death.mp3'
        //'damage2.mp3',
      ];
    case SfxType.waka:
      return const [
        'pacman_waka_ka.mp3',
        //'pacman_waka_wa.mp3',
      ];
    case SfxType.buttonTap:
      return const [
        'click1.mp3',
        'click2.mp3',
        'click3.mp3',
        'click4.mp3',
      ];
  }
}

/// Allows control over loudness of different SFX types.
double soundTypeToVolume(SfxType type) {
  switch (type) {
    case SfxType.waka:
    case SfxType.ghostsScared:
    case SfxType.doubleJump:
    case SfxType.pacmanDeath:
    case SfxType.eatGhost:
      return 0.4;
    case SfxType.buttonTap:
      return 1.0;
  }
}

enum SfxType {
  waka,
  ghostsScared,
  doubleJump,
  eatGhost,
  pacmanDeath,
  buttonTap,
}
