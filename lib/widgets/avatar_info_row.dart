import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'home_background.dart';
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

    final homeScope = HomeBackgroundScope.maybeOf(context);
    final hasHomeBackground = homeScope?.enabled == true;
    final avatarMaterial = Material(
      key: avatarShadowKey,
      color: hasHomeBackground
          ? Colors.transparent
          : colors.surfaceContainerHigh,
      surfaceTintColor: hasHomeBackground ? Colors.transparent : null,
      elevation: 5,
      shadowColor: shadowColor,
      shape: hasHomeBackground
          ? avatarShape.copyWith(side: BorderSide.none)
          : avatarShape,
      clipBehavior: Clip.antiAlias,
      child: avatar,
    );
    final cardMaterial = Material(
      key: cardKey,
      color: hasHomeBackground
          ? Colors.transparent
          : cardColor ?? colors.surface,
      surfaceTintColor: hasHomeBackground ? Colors.transparent : null,
      elevation: 5,
      shadowColor: shadowColor,
      shape: hasHomeBackground
          ? cardShape.copyWith(side: BorderSide.none)
          : cardShape,
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: cardPadding, child: child),
    );

    return Padding(
      padding: rowPadding,
      child: Row(
        children: [
          hasHomeBackground
              ? HomeBackdropCard(
                  shape: avatarShape,
                  color: homeCardSurfaceColor(
                    context,
                    colors.surfaceContainerHigh,
                  ),
                  child: avatarMaterial,
                )
              : avatarMaterial,
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
            child: hasHomeBackground
                ? HomeBackdropCard(
                    shape: cardShape,
                    color: homeCardSurfaceColor(
                      context,
                      cardColor ?? colors.surface,
                    ),
                    child: cardMaterial,
                  )
                : cardMaterial,
          ),
        ],
      ),
    );
  }
}
