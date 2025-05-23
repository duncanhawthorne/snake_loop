import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
// ignore: depend_on_referenced_packages
import 'package:web/web.dart' as web;

import '../constants.dart';

/// This file runs only on the web and contains fixes for iOS safari / chrome

final bool isiOSMobile = kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

void titleFixPermReal() {
  //https://github.com/flutter/flutter/issues/98248#issuecomment-2351689196
  if (isiOSMobile) {
    setUrlStrategy(CustomPathStrategy(appTitle: appTitle));
  }
}

class CustomPathStrategy extends PathUrlStrategy {
  CustomPathStrategy({required this.appTitle});

  final String appTitle;

  @override
  void pushState(Object? state, String title, String url) {
    final String pageTitle = title == "flutter" ? appTitle : title;
    super.pushState(state, pageTitle, url);
  }

  @override
  void replaceState(Object? state, String title, String url) {
    final String pageTitle = title == "flutter" ? appTitle : title;
    super.pushState(state, pageTitle, url);
  }
}

final bool isPwa =
    kIsWeb && web.window.matchMedia('(display-mode: standalone)').matches;
// Check if it's web iOS
final bool isWebiOS =
    kIsWeb &&
    web.window.navigator.userAgent.contains(RegExp(r'iPad|iPod|iPhone'));

const double _iOSWebPWAInset = 25;

double gestureInsetReal() {
  // Check if it's an installed PWA
  return isPwa && isWebiOS ? _iOSWebPWAInset : 0;
}
