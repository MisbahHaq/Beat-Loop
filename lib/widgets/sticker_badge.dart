import 'dart:math';
import 'package:flutter/material.dart';
import '../theme.dart';

class StickerBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final double size;
  final double angle;
  final TextStyle? labelStyle;
  final IconData? icon;

  const StickerBadge({
    super.key,
    required this.label,
    this.backgroundColor = AppTheme.cyberYellow,
    this.borderColor = AppTheme.ink,
    this.textColor = AppTheme.ink,
    this.size = 64,
    this.angle = 0,
    this.labelStyle,
    this.icon,
  });

  factory StickerBadge.pink({
    required String label,
    double size = 64,
    double angle = 0,
    IconData? icon,
  }) {
    return StickerBadge(
      label: label,
      backgroundColor: AppTheme.hotPink,
      textColor: Colors.white,
      size: size,
      angle: angle,
      icon: icon,
    );
  }

  factory StickerBadge.cyan({
    required String label,
    double size = 64,
    double angle = 0,
    IconData? icon,
  }) {
    return StickerBadge(
      label: label,
      backgroundColor: AppTheme.electricCyan,
      size: size,
      angle: angle,
      icon: icon,
    );
  }

  factory StickerBadge.yellow({
    required String label,
    double size = 64,
    double angle = 0,
    IconData? icon,
  }) {
    return StickerBadge(
      label: label,
      backgroundColor: AppTheme.cyberYellow,
      size: size,
      angle: angle,
      icon: icon,
    );
  }

  factory StickerBadge.orange({
    required String label,
    double size = 64,
    double angle = 0,
    IconData? icon,
  }) {
    return StickerBadge(
      label: label,
      backgroundColor: AppTheme.vibrantOrange,
      textColor: Colors.white,
      size: size,
      angle: angle,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle * pi / 180,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: 3),
          boxShadow: [
            BoxShadow(
              color: borderColor,
              offset: const Offset(3, 3),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: textColor, size: size * 0.35)
              : Text(
                  label,
                  style: (labelStyle ?? AppTheme.monoAccent).copyWith(
                    color: textColor,
                    fontSize: size * 0.18,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
