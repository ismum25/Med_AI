import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';

class FloatingGlassNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  const FloatingGlassNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.surfaceContainerLowest.withValues(alpha: 0.86),
                    AppColors.surfaceContainerLow.withValues(alpha: 0.68),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: AppColors.appBarBorder.withValues(alpha: 0.86),
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: SizedBox(
                height: 74,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth =
                        constraints.maxWidth / destinations.length;

                    return Stack(
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutCubic,
                          left: selectedIndex * itemWidth + 4,
                          top: 8,
                          width: itemWidth - 8,
                          height: 58,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.18),
                                  AppColors.accent.withValues(alpha: 0.14),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                        ),
                        Row(
                          children: List.generate(destinations.length, (index) {
                            final destination = destinations[index];
                            final selected = selectedIndex == index;
                            final icon = selected
                                ? destination.selectedIcon ?? destination.icon
                                : destination.icon;

                            return Expanded(
                              child: Semantics(
                                selected: selected,
                                label: destination.label,
                                button: true,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 8,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: () => onDestinationSelected(index),
                                      borderRadius: BorderRadius.circular(22),
                                      child: SizedBox(
                                        height: 58,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AnimatedScale(
                                              scale: selected ? 1.06 : 1,
                                              duration: const Duration(
                                                milliseconds: 220,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              child: IconTheme(
                                                data: IconThemeData(
                                                  color: selected
                                                      ? AppColors.primary
                                                      : AppColors
                                                          .onSurfaceVariant,
                                                  size: 22,
                                                ),
                                                child: icon,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Flexible(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: AnimatedDefaultTextStyle(
                                                  duration: const Duration(
                                                    milliseconds: 220,
                                                  ),
                                                  curve: Curves.easeOutCubic,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 10,
                                                    fontWeight: selected
                                                        ? FontWeight.w700
                                                        : FontWeight.w600,
                                                    color: selected
                                                        ? AppColors.primary
                                                        : AppColors
                                                            .onSurfaceVariant,
                                                  ),
                                                  child: Text(
                                                    destination.label,
                                                    maxLines: 1,
                                                    softWrap: false,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
