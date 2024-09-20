import 'pellet.dart';

class Food extends Pellet {
  Food({required super.position})
      : super(radiusFactor: 2, hitBoxRadiusFactor: (1 + 0.5));
}
