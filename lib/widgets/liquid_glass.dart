import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'soft_superellipse_border.dart';

class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blurSigma;
  final double elevation;
  final Color? shadowColor;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = AppRadii.surface,
    this.padding = const EdgeInsets.all(12),
    this.margin = EdgeInsets.zero,
    this.blurSigma = 12,
    this.elevation = 0,
    this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final glassBackground = isLight
        ? AppColors.lightGlassBackground
        : AppColors.glassBackground;
    final glassBorder = isLight
        ? AppColors.lightGlassBorder
        : AppColors.glassBorder;
    final shape = SoftSuperellipseBorder(
      side: BorderSide(color: glassBorder, width: 0.8),
      borderRadius: BorderRadius.circular(borderRadius),
      exponent: SoftSuperellipseBorder.defaultExponent,
    );

    final resolvedShadowColor =
        shadowColor ??
        (isLight
            ? Colors.black.withValues(alpha: 0.24)
            : Colors.black.withValues(alpha: 0.48));
    final glassSurface = Material(
      color: glassBackground,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
    final glassContent = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      clipBehavior: Clip.antiAlias,
      child: blurSigma <= 0
          ? glassSurface
          : BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: glassSurface,
            ),
    );

    return Padding(
      padding: margin,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (elevation > 0)
            Positioned.fill(
              child: PhysicalShape(
                key: const ValueKey('liquid-glass-shadow'),
                clipper: ShapeBorderClipper(shape: shape),
                color: Colors.transparent,
                shadowColor: resolvedShadowColor,
                elevation: elevation,
                clipBehavior: Clip.antiAlias,
                child: const SizedBox.expand(),
              ),
            ),
          glassContent,
        ],
      ),
    );
  }
}
