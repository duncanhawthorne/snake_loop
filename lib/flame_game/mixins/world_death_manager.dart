import 'package:flame/components.dart';

import '../../audio/sounds.dart';
import '../components/pacman.dart';
import '../components/wrapper_no_events.dart';
import '../pacman_game.dart';
import '../pacman_world.dart';

class WorldDeathManager extends WrapperNoEvents
    with HasGameReference<PacmanGame>, HasWorldReference<PacmanWorld> {
  WorldDeathManager();

  bool doingLevelResetFlourish = false;
  static const bool _slideCharactersAfterPacmanDeath = true;

  void resetAfterPacmanDeath(Pacman dyingPacman) {
    _resetSlideAfterPacmanDeath(dyingPacman);
  }

  void _resetSlideAfterPacmanDeath(Pacman dyingPacman) {
    //reset ghost scared status. Shouldn't be relevant as just died
    game.audioController.stopSound(SfxType.ghostsScared);
    if (!game.isWonOrLost) {
      if (_slideCharactersAfterPacmanDeath) {
        world.dragManager.flourishReset(_resetInstantAfterPacmanDeath);
        dyingPacman.resetSlideAfterDeath();
        world.ghosts.resetSlideAfterPacmanDeath();
      } else {
        _resetInstantAfterPacmanDeath();
      }
    } else {
      doingLevelResetFlourish = false;
    }
  }

  void _resetInstantAfterPacmanDeath() {
    // ignore: dead_code
    if (true || doingLevelResetFlourish) {
      // originally thought must test doingLevelResetFlourish
      // as could have been removed by reset during delay x 2
      // but this code is only run from resetSlide,
      // so if we have got here (accidentally) then resetSlide has run
      // and rotation will be wrong
      // so should clean up anyway
      if (game.level.infLives) {
        game.numberOfDeathsNotifier.value = 0;
        world.pacmans.pacmanDyingNotifier.value = 0;
      }
      world.pacmans.resetInstantAfterPacmanDeath();
      world.ghosts.resetInstantAfterPacmanDeath();
      world.dragManager.reset();
      doingLevelResetFlourish = false;
      if (game.playbackMode) {
        game.reset();
      } else {
        world.activityMonitor.reset();
      }
    }
  }

  @override
  Future<void> reset() async {
    doingLevelResetFlourish = false;
  }
}
