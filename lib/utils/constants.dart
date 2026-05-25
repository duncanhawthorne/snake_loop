import 'package:flutter/foundation.dart';

const String appTitle = "Snake LOOP";
final bool isiOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;

const bool enableRotationRaceMode = kDebugMode && false;
const int spriteVsPhysicsScale = 1;
const bool openSpaceMovement = false;

const bool drawDebugBoxes = kDebugMode && true;
