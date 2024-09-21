import 'package:flutter/material.dart';

import 'palette.dart';

Widget popupDialog({required List<Widget> children}) {
  return Center(
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: Padding(
        padding: const EdgeInsets.all(75.0),
        child: Container(
          decoration: BoxDecoration(
              border: Border.all(color: Palette.seed.color, width: 3),
              borderRadius: BorderRadius.circular(10),
              color: Palette.background.color),
          child: Padding(
              padding: const EdgeInsets.fromLTRB(40.0, 12, 40, 12),
              child: Column(
                  spacing: 16,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: children)),
        ),
      ),
    ),
  );
}

Widget titleWidget({required Widget child}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
    child: child,
  );
}

Widget titleText({required String text}) {
  return titleWidget(
    child: Text(text, style: textStyleHeading, textAlign: TextAlign.center),
  );
}

Widget bodyWidget({required Widget child}) {
  return child;
}

Widget bottomRowWidget({required List<Widget> children}) {
  return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Row(
          spacing: 10,
          children: List<Widget>.generate(
              children.length, (int index) => children[index],
              growable: false)));
}

const TextStyle textStyleHeading =
    TextStyle(fontFamily: 'Press Start 2P', fontSize: 28);

const TextStyle textStyleBody =
    TextStyle(fontFamily: 'Press Start 2P', color: Palette.textColor);

const TextStyle textStyleBodyDull =
    TextStyle(fontFamily: 'Press Start 2P', color: Palette.dullColor);

ButtonStyle buttonStyle(
    {Color borderColor = Palette.seedColor, bool small = false}) {
  return TextButton.styleFrom(
    minimumSize: Size.zero,
    padding: EdgeInsets.all(small ? 16 : 24),
    shape: RoundedRectangleBorder(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      side: BorderSide(
        color: borderColor,
        width: 3,
      ),
    ),
  );
}
