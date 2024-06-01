import '../level_selection/levels.dart';
import '../style/palette.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nes_ui/nes_ui.dart';
import 'package:provider/provider.dart';

/// This dialog is shown when a level is completed.
///
/// It shows what time the level was completed in and if there are more levels
/// it lets the user go to the next level, or otherwise back to the level
/// selection screen.
class GameLoseDialog extends StatelessWidget {
  const GameLoseDialog({
    super.key,
    required this.level,
    required this.levelCompletedIn,
  });

  /// The properties of the level that was just finished.
  final GameLevel level;

  /// How many seconds that the level was completed in.
  final int levelCompletedIn;

  @override
  Widget build(BuildContext context) {
    final palette = context.read<Palette>();
    return Center(
      child: NesContainer(
        width: 420,
        height: 300,
        backgroundColor: palette.backgroundPlaySession.color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'You died',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 16),
            if (true) ...[
              NesButton(
                onPressed: () {
                  context.go('/');
                },
                type: NesButtonType.primary,
                child: const Text('Retry',
                    style: TextStyle(fontFamily: 'Press Start 2P')),
              ),
              const SizedBox(height: 16),
            ],
            //NesButton(
            //  onPressed: () {
            //    context.go('/play');
            //  },
            //  type: NesButtonType.normal,
            //  child: const Text('Level selection'),
            //),
          ],
        ),
      ),
    );
  }
}
