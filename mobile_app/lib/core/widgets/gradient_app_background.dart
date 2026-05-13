import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GradientAppBackground extends StatelessWidget {
  final Widget child;

  const GradientAppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: AppColors.appBackgroundGradient,
      ),
      child: child,
    );
  }
}
