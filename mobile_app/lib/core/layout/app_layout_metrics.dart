import 'package:flutter/material.dart';

class AppLayoutMetrics {
  static const double navBarHeight = 74;
  static const double navBarBottomMargin = 12;
  static const double navBarTopClearance = 16;

  static double bottomNavReserve(BuildContext context) {
    return navBarTopClearance;
  }

  static EdgeInsets scrollPadding(
    BuildContext context, {
    double left = 20,
    double top = 16,
    double right = 20,
    double extraBottom = 0,
  }) {
    return EdgeInsets.fromLTRB(
      left,
      top,
      right,
      bottomNavReserve(context) + extraBottom,
    );
  }
}
