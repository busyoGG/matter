import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'soft_superellipse_border.dart';

/// A list row with an elevated avatar, a visual separator, and an elevated
/// continuous-corner information card.
class AvatarInfoRow extends StatelessWidget {
  final Widget avatar;
  final Widget child;
  final Color? cardColor;
  final EdgeInsetsGeometry cardPadding;
  final EdgeInsetsGeometry rowPadding;
  final Key? avatarShadowKey;
  final Key? separatorKey;
  final Key? cardKey;

  const AvatarInfoRow({
    super.key,
    required this.avatar,
    required this.child,
    this.cardColor,
    this.cardPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.rowPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    this.avatarShadowKey,
    this.separatorKey,
    this.cardKey,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shadowColor = colors.brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.42)
        : Colors.black.withValues(alpha: 0.26);
    final borderSide = BorderSide(
      color: colors.outlineVariant.withValues(alpha: 0.45),
      width: 1.5,
    );
    final avatarShape = SoftSuperellipseBorder(
      side: borderSide,
      borderRadius: BorderRadius.circular(AppRadii.avatar),
      exponent: SoftSuperellipseBorder.defaultExponent,
    );
    final cardShape = SoftSuperellipseBorder(
      side: borderSide,
      borderRadius: BorderRadius.circular(AppRadii.card),
      exponent: SoftSuperellipseBorder.defaultExponent,
    );

    return Padding(
      padding: rowPadding,
      child: Row(
        children: [
          Material(
            key: avatarShadowKey,
            color: colors.surfaceContainerHigh,
            elevation: 5,
            shadowColor: shadowColor,
            shape: avatarShape,
            clipBehavior: Clip.antiAlias,
            child: avatar,
          ),
          const SizedBox(width: 9),
          Container(
            key: separatorKey,
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Material(
              key: cardKey,
              color: cardColor ?? colors.surfaceContainerLow,
              elevation: 5,
              shadowColor: shadowColor,
              shape: cardShape,
              clipBehavior: Clip.antiAlias,
              child: Padding(padding: cardPadding, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
