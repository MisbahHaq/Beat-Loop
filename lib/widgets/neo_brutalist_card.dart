import 'package:flutter/material.dart';
import '../theme.dart';

class NeoBrutalistCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double borderWidth;
  final Offset shadowOffset;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const NeoBrutalistCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderWidth = AppTheme.borderMed,
    this.shadowOffset = AppTheme.shadowOffset,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.borderRadius,
    this.onTap,
  });

  const NeoBrutalistCard.small({
    super.key,
    required this.child,
    this.backgroundColor,
    this.shadowOffset = AppTheme.shadowOffsetSm,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.onTap,
  })  : borderWidth = AppTheme.borderThin,
        borderRadius = null;

  const NeoBrutalistCard.accent({
    super.key,
    required this.child,
    required Color accentColor,
    this.shadowOffset = AppTheme.shadowOffset,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.width,
    this.height,
    this.onTap,
  })  : backgroundColor = accentColor,
        borderWidth = AppTheme.borderMed,
        borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.paperWhite,
        border: Border.all(
          color: AppTheme.ink,
          width: borderWidth,
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink,
            offset: shadowOffset,
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
