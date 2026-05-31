import 'pellet.dart';

/// A larger collectible pellet that makes ghosts vulnerable.
class SuperPellet extends Pellet {
  SuperPellet({
    required super.position,
    required super.pelletsRemainingNotifier,
  }) : super(hitBoxRadiusFactor: 0.5);
}
