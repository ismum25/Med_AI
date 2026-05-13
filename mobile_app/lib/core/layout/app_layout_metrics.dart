import 'package:flutter/material.dart';

class AppLayoutMetrics {
  static const double navBarHeight = 64;
  static const double navBarBottomMargin = 12;
  static const double navBarSideMargin = 12;
  static const double navBarTopGap = 12;

  /// Total vertical space reserved by the floating nav bar.
  /// Use as bottom padding in scroll views and list content.
  static double bottomNavReserve(BuildContext context) {
    return navBarHeight +
        navBarBottomMargin +
        navBarTopGap +
        MediaQuery.viewPaddingOf(context).bottom;
  }

  /// Small bottom gap for FABs inside shell pages.
  /// The shell body already excludes the nav-bar footprint (extendBody:false),
  /// so FABs only need a tiny breathing-room offset.
  static const double fabGap = 8.0;

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
