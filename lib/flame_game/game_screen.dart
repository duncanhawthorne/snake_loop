import 'package:elapsed_time_display/elapsed_time_display.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../audio/audio_controller.dart';
import '../level_selection/levels.dart';
import '../main_menu/main_menu_screen.dart';
import '../player_progress/player_progress.dart';
import '../settings/settings.dart';
import 'dialogs/game_lose_dialog.dart';
import 'dialogs/game_start_dialog.dart';
import 'dialogs/game_won_dialog.dart';
import 'icons/pacman_icons.dart';
import 'pacman_game.dart';
import 'pacman_world.dart';

/// This widget defines the properties of the game screen.
///
/// It mostly sets up the overlays (widgets shown on top of the Flame game) and
/// the gets the [AudioController] from the context and passes it in to the
/// [PacmanGame] class so that it can play audio.

const double statusWidgetHeightFactor = 0.75;
const statusWidgetHeight = 30;

class GameScreen extends StatelessWidget {
  const GameScreen({required this.level, super.key});

  final GameLevel level;

  static const String loseDialogKey = 'lose_dialog';
  static const String wonDialogKey = 'won_dialog';
  static const String startDialogKey = 'start_dialog';
  static const String topLeftOverlayKey = 'top_left_overlay';
  static const String topRightOverlayKey = 'top_right_overlay';

  @override
  Widget build(BuildContext context) {
    final audioController = context.read<AudioController>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: GameWidget<PacmanGame>(
          key: const Key('play session'),
          game: PacmanGame(
            level: level,
            playerProgress: context.read<PlayerProgress>(),
            audioController: audioController,
            //palette: palette,
          ),
          overlayBuilderMap: {
            topLeftOverlayKey: (BuildContext context, PacmanGame game) {
              return topLeftOverlayWidget(context, game);
            },
            topRightOverlayKey: (BuildContext context, PacmanGame game) {
              return topRightOverlayWidget(context, game);
            },
            loseDialogKey: (BuildContext context, PacmanGame game) {
              return GameLoseDialog(
                level: level,
                game: game,
              );
            },
            wonDialogKey: (BuildContext context, PacmanGame game) {
              return GameWonDialog(
                  level: level,
                  levelCompletedInMillis: game.stopwatchMilliSeconds,
                  game: game);
            },
            startDialogKey: (BuildContext context, PacmanGame game) {
              return StartDialog(level: level, game: game);
            }
          },
        ),
      ),
    );
  }
}

Widget topLeftOverlayWidget(BuildContext context, PacmanGame game) {
  final settingsController = context.watch<SettingsController>();
  return Positioned(
    top: 20,
    left: 25, //30
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            if (overlayMainMenu) {
              game.overlays.add(GameScreen.startDialogKey);
            } else {
              GoRouter.of(context).go("/");
            }
          },
          icon: const Icon(overlayMainMenu ? Icons.menu : Icons.arrow_back,
              color: Colors.white),
        ),
        const SizedBox(width: 20 * statusWidgetHeightFactor, height: 1),
        audioOnOffButton(settingsController, color: Colors.white),
      ],
    ),
  );
}

Widget topRightOverlayWidget(BuildContext context, PacmanGame game) {
  return Positioned(
    top: 27,
    right: 30,
    child: Container(
      height: statusWidgetHeight.toDouble(),
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //FIXME first ElapsedTimeDisplay shouldn't be necessary
          //but without it the pacman icon doesn't animate
          ElapsedTimeDisplay(
            startTime: DateTime.now(), //actually ignored
            interval: const Duration(milliseconds: 100),
            style: const TextStyle(
                fontSize: 1 * statusWidgetHeightFactor,
                color: Colors.transparent,
                fontFamily: 'Press Start 2P'),
            formatter: (elapsedTime) {
              return elapsedTime.milliseconds.toString().padLeft(4, " ");
            },
          ),
          ValueListenableBuilder<int>(
            valueListenable: game.world.numberOfDeathsNotifier,
            builder: (BuildContext context, int value, Widget? child) {
              return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: List.generate(
                      game.level.maxAllowedDeaths,
                      (index) => Padding(
                          padding: const EdgeInsets.fromLTRB(
                              4 * statusWidgetHeightFactor,
                              0,
                              4 * statusWidgetHeightFactor,
                              0),
                          child: animatedPacmanIcon(game, index))));
            },
          ),
          const SizedBox(width: 20 * statusWidgetHeightFactor, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
            child: ElapsedTimeDisplay(
              startTime: DateTime.now(), //actually ignored
              interval: const Duration(milliseconds: 100),
              style: const TextStyle(
                  fontSize: 18 * statusWidgetHeightFactor,
                  color: Colors.white,
                  fontFamily: 'Press Start 2P'),
              formatter: (elapsedTime) {
                return (game.stopwatchMilliSeconds / 1000)
                    .toStringAsFixed(1)
                    .padLeft(4, " ");
              },
            ),
          ),
        ],
      ),
    ),
  );
}
