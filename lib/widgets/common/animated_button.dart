import 'package:flutter/material.dart';
import '../../theme/admin_theme.dart';

class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final double? elevation;
  final Size? minimumSize;
  final bool isLoading;

  const AnimatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.padding,
    this.borderRadius,
    this.elevation,
    this.minimumSize,
    this.isLoading = false,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(
                  widget.borderRadius ?? AdminTheme.radiusSm,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.backgroundColor ?? AdminTheme.primaryPurple)
                        .withOpacity(0.3 * _glowAnimation.value),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: 2 * _glowAnimation.value,
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.backgroundColor ?? AdminTheme.primaryPurple,
                  foregroundColor: widget.foregroundColor ?? Colors.white,
                  padding: widget.padding ?? 
                    const EdgeInsets.symmetric(
                      horizontal: AdminTheme.spacingXl,
                      vertical: AdminTheme.spacingMd,
                    ),
                  elevation: widget.elevation ?? 0,
                  shadowColor: Colors.transparent,
                  minimumSize: widget.minimumSize ?? const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius ?? AdminTheme.radiusSm,
                    ),
                  ),
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}


