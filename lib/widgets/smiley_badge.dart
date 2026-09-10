import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class SmileyBadge extends StatelessWidget {
  final double size;
  final Color color;
  final double angle;

  const SmileyBadge({
    super.key,
    this.size = 40,
    this.color = AppTheme.cyberYellow,
    this.angle = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * pi / 180,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: AppTheme.ink, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: AppTheme.ink,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: CustomPaint(
          painter: _SmileyPainter(),
        ),
      ),
    );
  }
}

class _SmileyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final inkPaint = Paint()
      ..color = AppTheme.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = AppTheme.ink
      ..style = PaintingStyle.fill;

    // Eyes
    final eyeOffsetX = radius * 0.3;
    final eyeOffsetY = radius * 0.2;
    canvas.drawCircle(Offset(center.dx - eyeOffsetX, center.dy - eyeOffsetY), radius * 0.08, dotPaint);
    canvas.drawCircle(Offset(center.dx + eyeOffsetX, center.dy - eyeOffsetY), radius * 0.08, dotPaint);

    // Smile
    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.15),
      width: radius * 0.8,
      height: radius * 0.5,
    );
    canvas.drawArc(smileRect, 0.1 * pi, 0.8 * pi, false, inkPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
