import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final double? height;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.borderColor,
    this.boxShadow,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: AdminTheme.glassGradient,
        borderRadius: BorderRadius.circular(borderRadius ?? AdminTheme.radiusMd),
        border: Border.all(
          color: borderColor ?? AdminTheme.glassStroke,
          width: 1,
        ),
        boxShadow: boxShadow ?? AdminTheme.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? AdminTheme.radiusMd),
        child: Container(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}



























