import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/home_background_provider.dart';
import 'home_background_image.dart';
import 'soft_superellipse_border.dart';

class HomeBackgroundPage extends ConsumerWidget {
  final Widget child;

  const HomeBackgroundPage({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final background = ref.watch(homeBackgroundProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final path = background.pathFor(dark: isDark);
    final colors = Theme.of(context).colorScheme;
    final enabled = path != null;
    return HomeBackgroundScope(
      enabled: enabled,
      cardBlurSigma: background.cardBlurSigma,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: ColoredBox(
              key: const ValueKey('home-background-base'),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          ),
          if (path != null)
            Positioned.fill(
              child: HomeBackgroundImage(
                key: ValueKey('home-background-image-$path'),
                path: path,
                opacity: background.imageOpacity,
              ),
            ),
          if (path != null && isDark && background.darkenEnabled)
            Positioned.fill(
              child: ColoredBox(
                key: const ValueKey('home-background-darken'),
                color: Colors.black.withValues(
                  alpha: background.darkenStrength,
                ),
              ),
            ),
          if (path != null)
            Positioned.fill(
              child: ColoredBox(
                key: const ValueKey('home-background-scrim'),
                color: colors.scrim.withValues(alpha: 0.04),
              ),
            ),
          BackdropGroup(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(overscroll: false),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class HomeBackgroundScope extends InheritedWidget {
  final bool enabled;
  final double cardBlurSigma;

  const HomeBackgroundScope({
    super.key,
    required this.enabled,
    this.cardBlurSigma = homeBackgroundDefaultBlurSigma,
    required super.child,
  });

  static HomeBackgroundScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeBackgroundScope>();

  @override
  bool updateShouldNotify(HomeBackgroundScope oldWidget) =>
      oldWidget.enabled != enabled || oldWidget.cardBlurSigma != cardBlurSigma;
}

class HomeBackdropCard extends StatelessWidget {
  final ShapeBorder shape;
  final Color color;
  final Widget child;
  final Key? filterKey;

  const HomeBackdropCard({
    super.key,
    required this.shape,
    required this.color,
    required this.child,
    this.filterKey,
  });

  @override
  Widget build(BuildContext context) {
    final scope = HomeBackgroundScope.maybeOf(context);
    final enabled = scope?.enabled == true;
    final surface = DecoratedBox(
      decoration: ShapeDecoration(shape: shape, color: color),
      child: child,
    );
    if (!enabled || scope!.cardBlurSigma <= 0.0) {
      return ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: surface,
      );
    }
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: BackdropFilter.grouped(
        key: filterKey,
        filter: ui.ImageFilter.blur(
          sigmaX: scope.cardBlurSigma,
          sigmaY: scope.cardBlurSigma,
        ),
        child: surface,
      ),
    );
  }
}

SoftSuperellipseBorder homeCardShape({
  double borderRadius = 20,
  BorderSide side = BorderSide.none,
}) => SoftSuperellipseBorder(
  side: side,
  borderRadius: BorderRadius.circular(borderRadius),
  exponent: SoftSuperellipseBorder.defaultExponent,
);

Color homeCardSurfaceColor(BuildContext context, Color color) {
  if (HomeBackgroundScope.maybeOf(context)?.enabled != true) {
    return color;
  }
  final alpha = color.a * 0.72;
  return color.withValues(alpha: alpha.clamp(0.0, 1.0));
}
