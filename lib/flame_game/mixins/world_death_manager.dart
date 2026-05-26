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
    if (!game.session.isWonOrLost) {
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
    if (doingLevelResetFlourish) {
      if (game.level.infLives) {
        game.session.numberOfDeathsNotifier.value = 0;
        world.pacmans.pacmanDyingNotifier.value = 0;
      }
      world.pacmans.resetInstantAfterPacmanDeath();
      world.ghosts.resetInstantAfterPacmanDeath();
      world.dragManager.reset();
      doingLevelResetFlourish = false;
      if (game.playback.playbackMode) {
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
