import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

enum GradientBlurEdge { top, bottom }

/// A bounded Kawase backdrop blur whose radius fades to zero at one edge.
///
/// Every pass writes a complete filtered texture. The gradient changes the
/// sampling radius, not the output alpha, so the header never becomes a
/// transparent hole that reveals the page below it.
class GradientBackdropBlur extends StatefulWidget {
  static const _blurRadius = 5.0;
  static const _passCount = 5;
  static const defaultMaskExtent = 0.5;
  static const _strongTintAlpha = 0.92;
  static const _mediumTintAlpha = 0.56;
  static Future<ui.FragmentProgram>? _programFuture;

  final GradientBlurEdge edge;
  final Widget child;
  final Color? tintColor;
  final double maskExtent;

  const GradientBackdropBlur({
    super.key,
    required this.edge,
    required this.child,
    this.tintColor,
    this.maskExtent = defaultMaskExtent,
  });

  @override
  State<GradientBackdropBlur> createState() => _GradientBackdropBlurState();
}

class _GradientBackdropBlurState extends State<GradientBackdropBlur> {
  ui.FragmentProgram? _program;
  List<ui.FragmentShader>? _shaders;

  @override
  void initState() {
    super.initState();
    if (ui.ImageFilter.isShaderFilterSupported) {
      _loadShader();
    }
  }

  Future<void> _loadShader() async {
    try {
      final program = GradientBackdropBlur._programFuture ??=
          ui.FragmentProgram.fromAsset('shaders/gradient_backdrop_blur.frag');
      final loadedProgram = await program;
      if (!mounted) {
        return;
      }
      setState(() {
        _program = loadedProgram;
        _shaders = List<ui.FragmentShader>.generate(
          GradientBackdropBlur._passCount,
          (_) => loadedProgram.fragmentShader(),
        );
      });
    } catch (_) {
      // Keep the native bounded blur fallback when shader filters are not
      // available or the platform cannot compile this asset.
    }
  }

  double _normalizedExtent() {
    return widget.maskExtent.clamp(0.0, 1.0).toDouble();
  }

  Widget _buildSurface() {
    final tintColor = widget.tintColor;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (tintColor != null)
          DecoratedBox(
            decoration: BoxDecoration(gradient: _tintGradient(tintColor)),
          ),
      ],
    );
  }

  Widget _buildNativeBlur() {
    return BackdropFilter(
      key: const ValueKey('gradient-backdrop-blur-native-backdrop'),
      filterConfig: ImageFilterConfig.blur(
        sigmaX: GradientBackdropBlur._blurRadius,
        sigmaY: GradientBackdropBlur._blurRadius,
        bounded: true,
      ),
      blendMode: BlendMode.srcOver,
      child: _buildSurface(),
    );
  }

  Widget _buildKawaseBlur(Size size) {
    final shaders = _shaders;
    if (_program == null || shaders == null || size.height <= 0.0) {
      return _buildNativeBlur();
    }

    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final headerHeight = size.height * devicePixelRatio;
    final extent = _normalizedExtent();
    for (var index = 0; index < shaders.length; index++) {
      shaders[index]
        ..setFloat(2, GradientBackdropBlur._blurRadius * devicePixelRatio)
        ..setFloat(3, headerHeight)
        ..setFloat(4, index.toDouble())
        ..setFloat(5, GradientBackdropBlur._passCount.toDouble())
        ..setFloat(6, widget.edge == GradientBlurEdge.top ? 0.0 : 1.0)
        ..setFloat(7, extent);
    }

    Widget filtered = const SizedBox.expand();
    for (var index = shaders.length - 1; index >= 0; index--) {
      filtered = BackdropFilter(
        key: ValueKey('gradient-backdrop-kawase-pass-$index'),
        filter: ui.ImageFilter.shader(shaders[index]),
        blendMode: BlendMode.srcOver,
        child: filtered,
      );
    }
    return Stack(fit: StackFit.expand, children: [filtered, _buildSurface()]);
  }

  LinearGradient _tintGradient(Color color) {
    final strong = color.withValues(
      alpha: GradientBackdropBlur._strongTintAlpha,
    );
    final medium = color.withValues(
      alpha: GradientBackdropBlur._mediumTintAlpha,
    );
    return widget.edge == GradientBlurEdge.top
        ? LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [strong, medium, Colors.transparent],
            stops: const [0.0, 0.5, 1.0],
          )
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, medium, strong],
            stops: const [0.0, 0.5, 1.0],
          );
  }

  @override
  void dispose() {
    for (final shader in _shaders ?? const <ui.FragmentShader>[]) {
      shader.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        clipBehavior: Clip.hardEdge,
        child: LayoutBuilder(
          builder: (context, constraints) => _buildKawaseBlur(
            Size(constraints.maxWidth, constraints.maxHeight),
          ),
        ),
      ),
    );
  }
}

/// A translucent header surface backed by the shared top-edge radius gradient.
class FrostedHeaderBackground extends StatelessWidget {
  final Color backgroundColor;

  const FrostedHeaderBackground({super.key, required this.backgroundColor});

  @override
  Widget build(BuildContext context) {
    return GradientBackdropBlur(
      edge: GradientBlurEdge.top,
      child: ColoredBox(
        key: const ValueKey('header-gradient-blur-activation'),
        color: backgroundColor.withValues(alpha: 0.01),
      ),
    );
  }
}

/// A scrolling page shell with a stretched, radius-gradient top blur.
class GradientFrostedHeaderBackground extends StatefulWidget {
  final double headerHeight;
  final Widget child;
  final Widget? headerChild;

  const GradientFrostedHeaderBackground({
    super.key,
    required this.headerHeight,
    required this.child,
    this.headerChild,
  });

  @override
  State<GradientFrostedHeaderBackground> createState() =>
      _GradientFrostedHeaderBackgroundState();
}

class _GradientFrostedHeaderBackgroundState
    extends State<GradientFrostedHeaderBackground>
    with TickerProviderStateMixin {
  static const _exponentialScalar = math.e / 0.33;
  static const _stretchIntensity = 0.016;
  static const _flingVelocityFriction = 1 / 6000;
  static const _absorbImpactVelocityFriction = 1 / 3000;
  static const _maxFlingVelocity = 0.5;
  static const _maxAbsorbImpactVelocity = 1.25;
  static const _naturalFrequency = 24.657;
  static const _dampingRatio = 0.98;
  static const _timeCorrectionFactor = 0.8;
  static const _kStiffness = _naturalFrequency * _naturalFrequency;

  static final _stretchSpringDescription = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: _kStiffness * _timeCorrectionFactor * _timeCorrectionFactor,
    ratio: _dampingRatio,
  );

  final _stretchStrength = ValueNotifier<double>(0.0);
  late final AnimationController _stretchController =
      AnimationController.unbounded(vsync: this)..addListener(_stretchTick);
  int _stretchAnimationGeneration = 0;
  double _totalOverscroll = 0.0;
  AxisDirection _axisDirection = AxisDirection.down;

  void _stretchTick() {
    _stretchStrength.value = _stretchController.value
        .clamp(-1.0, 1.0)
        .toDouble();
  }

  void _pull(double normalizedOverscroll) {
    var interruptedOverscroll = 0.0;
    if (_stretchController.isAnimating) {
      interruptedOverscroll = _stretchController.value;
      _stretchAnimationGeneration++;
      _stretchController.stop(canceled: true);
    }
    final absDistance = normalizedOverscroll.abs();
    final linearIntensity = _stretchIntensity * absDistance;
    final exponentialIntensity =
        _stretchIntensity * (1 - math.exp(-absDistance * _exponentialScalar));
    final newOverscroll =
        normalizedOverscroll.sign * (linearIntensity + exponentialIntensity) +
        interruptedOverscroll;
    _stretchController.value = newOverscroll.clamp(-1.0, 1.0).toDouble();
    _stretchTick();
  }

  void _animateStretch(double velocity) {
    if (_stretchStrength.value == 0.0 && velocity == 0.0) {
      return;
    }
    final generation = ++_stretchAnimationGeneration;
    final scaledVelocity = velocity.clamp(
      -_maxFlingVelocity,
      _maxFlingVelocity,
    );
    _stretchController
        .animateWith(
          SpringSimulation(
            _stretchSpringDescription,
            _stretchStrength.value,
            0.0,
            scaledVelocity * _timeCorrectionFactor,
          ),
        )
        .whenCompleteOrCancel(() {
          if (mounted && generation == _stretchAnimationGeneration) {
            _stretchController.value = 0.0;
            _stretchTick();
          }
        });
  }

  void _absorbImpact(double velocity) {
    if (velocity == 0.0) {
      return;
    }
    final scaledVelocity = (velocity * _absorbImpactVelocityFriction).clamp(
      -_maxAbsorbImpactVelocity,
      _maxAbsorbImpactVelocity,
    );
    _animateStretch(scaledVelocity);
  }

  bool _handleRealtimeScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    _axisDirection = notification.metrics.axisDirection;
    if (notification is ScrollStartNotification) {
      _totalOverscroll = 0.0;
    } else if (notification is OverscrollNotification) {
      _totalOverscroll += notification.overscroll;
      if (notification.velocity != 0.0) {
        _absorbImpact(notification.velocity);
      } else if (notification.dragDetails != null) {
        final viewportDimension = notification.metrics.viewportDimension;
        final distanceForPull = _totalOverscroll / viewportDimension;
        _pull(distanceForPull.clamp(-1.0, 1.0).toDouble());
      }
    } else if (notification is ScrollUpdateNotification) {
      _totalOverscroll = 0.0;
      if (_stretchStrength.value != 0.0 && !_stretchController.isAnimating) {
        _animateStretch(0.0);
      }
    } else if (notification is ScrollEndNotification) {
      var velocity =
          notification.dragDetails?.velocity.pixelsPerSecond.dy ?? 0.0;
      if (notification.metrics.axisDirection == AxisDirection.up) {
        velocity = -velocity;
      }
      _totalOverscroll = 0.0;
      if (!_stretchController.isAnimating) {
        _animateStretch(-velocity * _flingVelocityFriction);
      }
    }
    return false;
  }

  double _safeHeaderHeight() {
    final headerHeight = widget.headerHeight;
    if (!headerHeight.isFinite || headerHeight <= 0.0) {
      return 0.0;
    }
    return headerHeight;
  }

  Widget _buildStack(
    BuildContext context, {
    required double headerHeight,
    required Widget headerFilter,
  }) {
    final child = ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: NotificationListener<ScrollNotification>(
          onNotification: _handleRealtimeScrollNotification,
          child: widget.child,
        ),
      ),
    );
    final headerChild = widget.headerChild;
    return Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        _buildWithStretch(child),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: headerHeight,
          child: SizedBox.expand(child: IgnorePointer(child: headerFilter)),
        ),
        if (headerChild != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: headerHeight,
            child: SizedBox.expand(child: IgnorePointer(child: headerChild)),
          ),
      ],
    );
  }

  Widget _buildWithStretch(Widget child) {
    return ValueListenableBuilder<double>(
      valueListenable: _stretchStrength,
      builder: (context, stretchStrength, child) => StretchEffect(
        stretchStrength: _axisDirection == AxisDirection.up
            ? stretchStrength
            : -stretchStrength,
        axis: Axis.vertical,
        child: child!,
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerHeight = _safeHeaderHeight();
    return _buildStack(
      context,
      headerHeight: headerHeight,
      headerFilter: GradientBackdropBlur(
        edge: GradientBlurEdge.top,
        child: ColoredBox(
          color: Theme.of(
            context,
          ).scaffoldBackgroundColor.withValues(alpha: 0.01),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stretchAnimationGeneration++;
    _stretchController.dispose();
    _stretchStrength.dispose();
    super.dispose();
  }
}
