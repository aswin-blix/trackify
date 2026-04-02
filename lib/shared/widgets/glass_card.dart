import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatefulWidget {
  final Widget child;
  final double blur;
  final double? opacity;
  final double borderRadius;
  final Color? borderColor;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double? width;
  final double? height;
  final BoxShadow? shadow;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity,
    this.borderRadius = 20,
    this.borderColor,
    this.gradient,
    this.padding,
    this.margin,
    this.onTap,
    this.onLongPress,
    this.width,
    this.height,
    this.shadow,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _brightnessAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.975).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutExpo),
    );
    _brightnessAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOutExpo),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _pressController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _onTapCancel() {
    _pressController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultOpacity = widget.opacity ?? (isDark ? 0.07 : 0.55);
    final defaultBorderColor = widget.borderColor ??
        Colors.white.withValues(alpha: isDark ? 0.15 : 0.4);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _pressController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: ColorFiltered(
              colorFilter: ColorFilter.matrix(
                  _brightnessMatrix(_brightnessAnimation.value)),
              child: child,
            ),
          );
        },
        child: Container(
          margin: widget.margin,
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: [
              widget.shadow ??
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blur,
                sigmaY: widget.blur,
              ),
              child: Container(
                padding: widget.padding,
                decoration: BoxDecoration(
                  gradient: widget.gradient ??
                      LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: defaultOpacity + 0.05),
                          Colors.white.withValues(alpha: defaultOpacity),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(widget.borderRadius),
                  border: Border.all(
                    color: defaultBorderColor,
                    width: 1.2,
                  ),
                ),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<double> _brightnessMatrix(double value) {
    return [
      value,
      0,
      0,
      0,
      0,
      0,
      value,
      0,
      0,
      0,
      0,
      0,
      value,
      0,
      0,
      0,
      0,
      0,
      1,
      0,
    ];
  }
}
