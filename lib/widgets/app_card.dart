import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'soft_superellipse_border.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({
    super.key,
    required this.child,
    this.borderRadius = AppRadii.surface,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final shape = SoftSuperellipseBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      exponent: SoftSuperellipseBorder.defaultExponent,
    );
    final content = Padding(padding: padding, child: child);
    final card = Material(
      color: color ?? Theme.of(context).colorScheme.surface,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? content
          : InkWell(customBorder: shape, onTap: onTap, child: content),
    );

    return Padding(padding: margin, child: card);
  }
}
