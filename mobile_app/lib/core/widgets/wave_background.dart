import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WaveBackground extends StatelessWidget {
  final double height;
  final Widget? child;

  const WaveBackground({
    super.key,
    required this.height,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _WaveClipper(),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                ),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(painter: _TopographicPainter()),
            ),
            if (child != null) Positioned.fill(child: child!),
          ],
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 32);
    path.quadraticBezierTo(
      size.width * 0.25, size.height,
      size.width * 0.55, size.height - 16,
    );
    path.quadraticBezierTo(
      size.width * 0.85, size.height - 40,
      size.width, size.height - 8,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _TopographicPainter extends CustomPainter {
  static const _lines = <_WaveSpec>[
    _WaveSpec(yFactor: 0.18, amp: 18, phase: 0.0, alpha: 0.10),
    _WaveSpec(yFactor: 0.28, amp: 24, phase: 0.3, alpha: 0.14),
    _WaveSpec(yFactor: 0.38, amp: 20, phase: 0.6, alpha: 0.10),
    _WaveSpec(yFactor: 0.48, amp: 28, phase: 0.1, alpha: 0.16),
    _WaveSpec(yFactor: 0.60, amp: 22, phase: 0.45, alpha: 0.12),
    _WaveSpec(yFactor: 0.72, amp: 26, phase: 0.25, alpha: 0.10),
    _WaveSpec(yFactor: 0.84, amp: 20, phase: 0.55, alpha: 0.08),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final spec in _lines) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: spec.alpha);
      final path = Path();
      final baseY = size.height * spec.yFactor;
      path.moveTo(-20, baseY);
      const segments = 4;
      final segW = (size.width + 40) / segments;
      for (var i = 0; i < segments; i++) {
        final x1 = -20 + segW * i + segW / 2;
        final x2 = -20 + segW * (i + 1);
        final dir = (i + spec.phase * 10).toInt().isEven ? -1 : 1;
        path.quadraticBezierTo(
          x1,
          baseY + spec.amp * dir,
          x2,
          baseY,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WaveSpec {
  final double yFactor;
  final double amp;
  final double phase;
  final double alpha;
  const _WaveSpec({
    required this.yFactor,
    required this.amp,
    required this.phase,
    required this.alpha,
  });
}
