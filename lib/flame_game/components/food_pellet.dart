import 'package:flame/components.dart';

import 'pellet.dart';

const double hitboxGenerosity = 0.5;

class Food extends Pellet {
  Food({required super.position, required super.pelletsRemainingNotifier})
    : super(radiusFactor: 2, hitBoxRadiusFactor: (1 + hitboxGenerosity));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = await Sprite.load('assets/images/apple.png');
    angle = world.dragRotate.downAngle;
  }
}
