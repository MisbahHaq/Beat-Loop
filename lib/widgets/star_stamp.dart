import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class StarStamp extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double angle;
  final int points;

  const StarStamp({
    super.key,
    this.size = 36,
    this.color = AppTheme.hotPink,
    this.borderColor = AppTheme.ink,
    this.angle = 0,
    this.points = 5,
  });

  const StarStamp.yellow({
    super.key,
    this.size = 36,
    this.angle = 0,
    this.points = 5,
  })  : color = AppTheme.cyberYellow,
        borderColor = AppTheme.ink;

  const StarStamp.pink({
    super.key,
    this.size = 36,
    this.angle = 0,
    this.points = 5,
  })  : color = AppTheme.hotPink,
        borderColor = AppTheme.ink;

  const StarStamp.cyan({
    super.key,
    this.size = 36,
    this.angle = 0,
    this.points = 5,
  })  : color = AppTheme.electricCyan,
        borderColor = AppTheme.ink;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * pi / 180,
      child: CustomPaint(
        size: Size(size, size),
        painter: _StarPainter(
          color: color,
          borderColor: borderColor,
          points: points,
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  final int points;

  _StarPainter({
    required this.color,
    required this.borderColor,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * 0.4;

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = borderColor
      ..strokeWidth = 2.5;

    final path = Path();
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = (i * pi / points) - pi / 2;
      final point = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
