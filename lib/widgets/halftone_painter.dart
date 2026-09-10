import 'dart:math';
import 'package:flutter/material.dart';

class HalftoneBackground extends StatelessWidget {
  final Widget child;
  final Color dotColor;
  final double dotSpacing;
  final double maxDotSize;

  const HalftoneBackground({
    super.key,
    required this.child,
    this.dotColor = const Color(0xFF111111),
    this.dotSpacing = 20,
    this.maxDotSize = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _HalftonePainter(
              dotColor: dotColor,
              spacing: dotSpacing,
              maxDotSize: maxDotSize,
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _HalftonePainter extends CustomPainter {
  final Color dotColor;
  final double spacing;
  final double maxDotSize;

  _HalftonePainter({
    required this.dotColor,
    required this.spacing,
    required this.maxDotSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = dotColor.withOpacity(0.08);

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final distFromCenter = sqrt(
          pow(x - size.width / 2, 2) + pow(y - size.height / 2, 2),
        );
        final maxDist = sqrt(pow(size.width / 2, 2) + pow(size.height / 2, 2));
        final t = distFromCenter / maxDist;
        final dotSize = maxDotSize * (0.3 + 0.7 * t);

        canvas.drawCircle(Offset(x, y), dotSize, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class HalftoneOverlay extends StatelessWidget {
  final double opacity;

  const HalftoneOverlay({super.key, this.opacity = 0.06});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: CustomPaint(
        painter: _HalftoneOverlayPainter(opacity: opacity),
      ),
    );
  }
}

class _HalftoneOverlayPainter extends CustomPainter {
  final double opacity;

  _HalftoneOverlayPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF111111).withOpacity(opacity);

    const spacing = 12.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), dotRadius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
