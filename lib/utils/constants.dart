import 'package:flutter/foundation.dart';

/// The display title of the application.
const String appTitle = "Snake LOOP";

/// Whether the app is running on iOS Safari (web).
final bool isiOSWeb = defaultTargetPlatform == TargetPlatform.iOS && kIsWeb;

const bool enableRotationRaceMode = kDebugMode && false;
const bool enableMovingWalls = kDebugMode && false;

const double physicsScale = 1;
const bool openSpaceMovement = false;

const bool drawDebugBoxes = kDebugMode && false;
