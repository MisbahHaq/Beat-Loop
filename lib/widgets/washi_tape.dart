import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

enum WashiPattern { stripes, polkaDot, solid, crossHatch }

class WashiTape extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final WashiPattern pattern;
  final double angle;
  final Alignment alignment;

  const WashiTape({
    super.key,
    this.width = 100,
    this.height = 24,
    this.color = const Color(0xFFFFC1D0),
    this.pattern = WashiPattern.stripes,
    this.angle = 0,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.rotate(
        angle: angle * pi / 180,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withOpacity(0.85),
            border: Border.all(color: AppTheme.ink.withOpacity(0.15), width: 0.5),
          ),
          child: CustomPaint(
            painter: _WashiPatternPainter(pattern: pattern, color: color),
          ),
        ),
      ),
    );
  }

  // Factory constructors for common configs
  factory WashiTape.striped({
    double width = 100,
    double height = 24,
    double angle = -3,
    Color color = const Color(0xFFFFC1D0),
    Alignment alignment = Alignment.topCenter,
  }) {
    return WashiTape(
      width: width,
      height: height,
      color: color,
      pattern: WashiPattern.stripes,
      angle: angle,
      alignment: alignment,
    );
  }

  factory WashiTape.polkaDot({
    double width = 100,
    double height = 24,
    double angle = 2,
    Color color = const Color(0xFFB8ECFF),
    Alignment alignment = Alignment.topCenter,
  }) {
    return WashiTape(
      width: width,
      height: height,
      color: color,
      pattern: WashiPattern.polkaDot,
      angle: angle,
      alignment: alignment,
    );
  }

  factory WashiTape.solid({
    double width = 80,
    double height = 24,
    double angle = -1,
    Color color = const Color(0xFFD8C4FF),
    Alignment alignment = Alignment.topCenter,
  }) {
    return WashiTape(
      width: width,
      height: height,
      color: color,
      pattern: WashiPattern.solid,
      angle: angle,
      alignment: alignment,
    );
  }

  factory WashiTape.crossHatch({
    double width = 110,
    double height = 24,
    double angle = 4,
    Color color = const Color(0xFFFFF3B0),
    Alignment alignment = Alignment.topCenter,
  }) {
    return WashiTape(
      width: width,
      height: height,
      color: color,
      pattern: WashiPattern.crossHatch,
      angle: angle,
      alignment: alignment,
    );
  }
}

class _WashiPatternPainter extends CustomPainter {
  final WashiPattern pattern;
  final Color color;

  _WashiPatternPainter({required this.pattern, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    switch (pattern) {
      case WashiPattern.stripes:
        paint.color = Colors.white.withOpacity(0.5);
        for (double x = 0; x < size.width; x += 6) {
          canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
        }
        break;

      case WashiPattern.polkaDot:
        final dotPaint = Paint()
          ..style = PaintingStyle.fill
          ..color = Colors.white.withOpacity(0.5);
        for (double x = 4; x < size.width; x += 10) {
          for (double y = 4; y < size.height; y += 10) {
            canvas.drawCircle(Offset(x, y), 2, dotPaint);
          }
        }
        break;

      case WashiPattern.solid:
        // Just the base color, no pattern
        break;

      case WashiPattern.crossHatch:
        paint.color = Colors.white.withOpacity(0.4);
        for (double x = -size.height; x < size.width + size.height; x += 8) {
          canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), paint);
          canvas.drawLine(Offset(x + size.height, 0), Offset(x, size.height), paint);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
