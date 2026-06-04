import 'package:flutter/material.dart';

class AppCurve {
  static BorderRadius top(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return BorderRadius.only(
      topLeft: Radius.circular(width * 0.08),
      topRight: Radius.circular(width * 0.08),
    );
  }
}
