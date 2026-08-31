import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

Widget _navigationBackdropFilter({
  Key? key,
  required double sigma,
  required Widget child,
}) {
  return BackdropFilter(
    key: key,
    filterConfig: ImageFilterConfig.blur(
      sigmaX: sigma,
      sigmaY: sigma,
      bounded: true,
    ),
    child: child,
  );
}

class FloatingBottomNavigationBar extends StatefulWidget {
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final bool visible;

  const FloatingBottomNavigationBar({
    super.key,
    required this.controller,
    required this.currentIndex,
    required this.onIndexChanged,
    this.visible = true,
  });

  @override
  State<FloatingBottomNavigationBar> createState() =>
      _FloatingBottomNavigationBarState();
}

class _FloatingBottomNavigationBarState
    extends State<FloatingBottomNavigationBar>
    with TickerProviderStateMixin {
  static const _itemCount = 4;
  static const _dragDuration = Duration(milliseconds: 240);
  static const _flingVelocity = 300.0;
  static const _jellyDuration = Duration(milliseconds: 360);
  static const _clickDuration = Duration(milliseconds: 405);

  late final AnimationController _jellyController;
  late final AnimationController _clickController;

  double _dragVisualProgress = 0;
  double _jellyStartProgress = 0;
  double _pressProgress = 0;
  _ClickAnimationMode _clickAnimationMode = _ClickAnimationMode.none;

  double? _dragStartPage;
  double? _dragIndicatorPage;
  Offset? _pointerDownPosition;
  Offset? _pointerDownGlobalPosition;
  double? _dragStartIndicatorCenter;
  double? _dragIndicatorCenter;
  int? _pointerId;
  VelocityTracker? _velocityTracker;
  bool _isDragging = false;
  bool _suppressTap = false;
  double _surfaceWidth = 0;

  static const _destinations = [
    _NavigationDestination(
      icon: Icons.chat_bubble_outline_rounded,
      activeIcon: Icons.chat_bubble_rounded,
      label: '聊天',
    ),
    _NavigationDestination(
      icon: Icons.account_tree_outlined,
      activeIcon: Icons.account_tree_rounded,
      label: '空间',
    ),
    _NavigationDestination(
      icon: Icons.people_outline_rounded,
      activeIcon: Icons.people_rounded,
      label: '通讯录',
    ),
    _NavigationDestination(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings_rounded,
      label: '设置',
    ),
  ];

  int get _currentIndex => widget.currentIndex.clamp(0, _itemCount - 1).toInt();

  @override
  void initState() {
    super.initState();
    _jellyController = AnimationController(
      vsync: this,
      duration: _jellyDuration,
    )..addListener(_onAnimationTick);
    _clickController = AnimationController(
      vsync: this,
      duration: _clickDuration,
    )..addListener(_onAnimationTick);
  }

  @override
  void dispose() {
    _jellyController.dispose();
    _clickController.dispose();
    super.dispose();
  }

  void _onAnimationTick() {
    _pressProgress = _clickController.value;
    if (mounted) setState(() {});
  }

  bool _hasUsablePosition() {
    final controller = widget.controller;
    if (!controller.hasClients || controller.positions.length != 1) {
      return false;
    }

    final position = controller.position;
    return position.hasPixels &&
        position.hasViewportDimension &&
        position.viewportDimension.isFinite &&
        position.viewportDimension > 0;
  }

  double? _readPage() {
    if (!_hasUsablePosition()) return null;
    try {
      final page = widget.controller.page;
      return page != null && page.isFinite
          ? page.clamp(0, _itemCount - 1).toDouble()
          : null;
    } catch (_) {
      return null;
    }
  }

  double _pageOrCurrentIndex() => _readPage() ?? _currentIndex.toDouble();

  double _visualProgress() {
    if (_isDragging) {
      return _dragVisualProgress.clamp(0.0, 1.0).toDouble();
    }
    if (_jellyController.value > 0 && _jellyController.value < 1) {
      final progress = _jellyController.value;
      if (progress < 0.28) {
        return _jellyStartProgress * (1 - progress / 0.28);
      }
      if (progress < 0.54) {
        return -0.35 * ((progress - 0.28) / 0.26);
      }
      if (progress < 0.76) {
        return 0.16 * ((progress - 0.54) / 0.22);
      }
      return 0.16 * (1 - (progress - 0.76) / 0.24);
    }
    return 0;
  }

  ({double scaleX, double scaleY}) _clickScale() {
    if (_clickAnimationMode == _ClickAnimationMode.none) {
      return (scaleX: 1, scaleY: 1);
    }

    final progress = _clickAnimationMode == _ClickAnimationMode.press
        ? _pressProgress
        : _clickController.value;
    if (_clickAnimationMode == _ClickAnimationMode.press) {
      if (progress < 0.2) {
        final segment = Curves.easeOut.transform(progress / 0.2);
        return (
          scaleX: 1 + (0.78 - 1) * segment,
          scaleY: 1 + (0.84 - 1) * segment,
        );
      }
      if (progress < 0.6) return (scaleX: 0.78, scaleY: 0.84);
      final segment = Curves.easeIn.transform((progress - 0.6) / 0.4);
      return (
        scaleX: 0.78 + (1 - 0.78) * segment,
        scaleY: 0.84 + (1 - 0.84) * segment,
      );
    }

    // Match ProcessManager's click transition: first compress vertically,
    // then overshoot slightly, and finally settle back to the capsule.
    const firstEnd = 105 / 405;
    const secondEnd = (105 + 130) / 405;
    if (progress < firstEnd) {
      final segment = Curves.easeOut.transform(progress / firstEnd);
      return (
        scaleX: 1 + (1.16 - 1) * segment,
        scaleY: 1 + (0.72 - 1) * segment,
      );
    }
    if (progress < secondEnd) {
      final segment = _overshoot(
        (progress - firstEnd) / (secondEnd - firstEnd),
      );
      return (
        scaleX: 1.16 + (1.08 - 1.16) * segment,
        scaleY: 0.72 + (1.08 - 0.72) * segment,
      );
    }
    final segment = Curves.easeOut.transform(
      (progress - secondEnd) / (1 - secondEnd),
    );
    return (
      scaleX: 1.08 + (1 - 1.08) * segment,
      scaleY: 1.04 + (1 - 1.04) * segment,
    );
  }

  double _overshoot(double value) {
    final t = value.clamp(0.0, 1.0).toDouble() - 1;
    return t * t * (3 * t + 2) + 1;
  }

  void _startPressAnimation() {
    _clickAnimationMode = _ClickAnimationMode.press;
    _clickController
      ..stop()
      ..value = 0;
    unawaited(
      _clickController.animateTo(
        1,
        duration: const Duration(milliseconds: 180),
        curve: Curves.linear,
      ),
    );
  }

  void _startClickAnimation() {
    _clickAnimationMode = _ClickAnimationMode.click;
    _clickController
      ..stop()
      ..value = 0;
    unawaited(
      _clickController.animateTo(
        1,
        duration: _clickDuration,
        curve: Curves.linear,
      ),
    );
  }

  void _startDragVisualState() {
    _clickController
      ..stop()
      ..value = 1;
    _clickAnimationMode = _ClickAnimationMode.none;
    _jellyController.stop();
  }

  void _startJellyRelease() {
    _jellyStartProgress = _dragVisualProgress.clamp(0.0, 1.0).toDouble();
    _dragVisualProgress = 0;
    _jellyController
      ..stop()
      ..value = 0;
    unawaited(_jellyController.forward(from: 0));
  }

  void _handlePointerDown(PointerDownEvent event) {
    _startPressAnimation();
    _suppressTap = false;
    _pointerId = event.pointer;
    _pointerDownPosition = event.localPosition;
    _pointerDownGlobalPosition = event.position;
    _velocityTracker = VelocityTracker.withKind(event.kind)
      ..addPosition(event.timeStamp, event.position);
    _dragStartPage = _pageOrCurrentIndex();
    final itemWidth = _surfaceWidth > 0 ? _surfaceWidth / _itemCount : 0.0;
    _dragStartIndicatorCenter = itemWidth > 0
        ? (_dragStartPage! * itemWidth) + itemWidth / 2
        : null;
    _dragIndicatorPage = null;
    _isDragging = false;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _pointerId || _pointerDownPosition == null) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);

    // Use screen-space movement. The recognizer may receive transformed local
    // coordinates while the PageView is jumping underneath it; global pointer
    // deltas remain exactly equal to the user's finger movement.
    final offset =
        event.position - (_pointerDownGlobalPosition ?? event.position);
    if (!_isDragging) {
      if (offset.distance < kTouchSlop || offset.dx.abs() <= offset.dy.abs()) {
        return;
      }
      _isDragging = _hasUsablePosition();
      _suppressTap = _isDragging;
      if (_isDragging) _startDragVisualState();
    }
    if (!_isDragging || !_hasUsablePosition()) return;

    final viewportWidth = widget.controller.position.viewportDimension;
    if (!viewportWidth.isFinite || viewportWidth <= 0) return;

    final startPage = _dragStartPage ?? _pageOrCurrentIndex();
    final itemWidth = _surfaceWidth > 0
        ? _surfaceWidth / _itemCount
        : viewportWidth / _itemCount;
    // Do not limit the drag to the adjacent tab. A tab-strip drag may cross
    // several pages in one continuous gesture, just like the PageView below.
    final page = (startPage + offset.dx / itemWidth).clamp(
      0.0,
      (_itemCount - 1).toDouble(),
    );
    // Start the enlargement as soon as the horizontal drag begins, then
    // increase it with distance. This makes the elastic state visible
    // immediately instead of waiting for a long swipe.
    // Once the gesture becomes a drag, keep the enlarged shape at every
    // horizontal position. Returning the finger to the start must not make
    // the indicator collapse back to its resting size.
    _dragVisualProgress = 1.0;
    _dragIndicatorPage = page;
    _dragIndicatorCenter =
        (_dragStartIndicatorCenter ?? (startPage * itemWidth + itemWidth / 2)) +
        offset.dx;
    try {
      widget.controller.jumpTo(page * viewportWidth);
      if (mounted) setState(() {});
    } catch (_) {
      _isDragging = false;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _pointerId) return;
    _velocityTracker?.addPosition(event.timeStamp, event.position);
    if (_isDragging) {
      final page = _pageOrCurrentIndex();
      final startPage = _dragStartPage ?? _currentIndex.toDouble();
      final startIndex = startPage.round().clamp(0, _itemCount - 1).toInt();
      final pageDelta = page - startPage;
      final velocity = _velocityTracker?.getVelocity().pixelsPerSecond.dx;
      final hasFling = velocity != null && velocity.abs() >= _flingVelocity;
      final direction = pageDelta.abs() > 0.001
          ? pageDelta.sign.toInt()
          : hasFling
          ? (velocity > 0 ? 1 : -1)
          : 0;
      final shouldAdvance = pageDelta.abs() >= 0.5 || hasFling;
      var target = shouldAdvance
          ? page.round().clamp(0, _itemCount - 1).toInt()
          : startIndex;
      // A fast fling that did not cross half a tab still advances exactly one
      // page, while a longer drag keeps the full multi-page displacement.
      if (hasFling && target == startIndex && direction != 0) {
        target = (startIndex + direction).clamp(0, _itemCount - 1).toInt();
      }
      _startJellyRelease();
      _settleToPage(target);
    } else if (!_suppressTap && _surfaceWidth > 0) {
      final itemWidth = _surfaceWidth / _itemCount;
      final target = (_pointerDownPosition!.dx / itemWidth)
          .floor()
          .clamp(0, _itemCount - 1)
          .toInt();
      if (target != _currentIndex) {
        _startClickAnimation();
        _settleToPage(target);
      }
    }
    _resetPointer();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _pointerId) {
      if (_isDragging) {
        _startJellyRelease();
        _settleToPage((_dragStartPage ?? _currentIndex.toDouble()).round());
      }
      _resetPointer();
    }
  }

  void _resetPointer() {
    final wasDragging = _isDragging;
    _pointerId = null;
    _pointerDownPosition = null;
    _velocityTracker = null;
    _dragStartPage = null;
    _dragIndicatorPage = null;
    _dragStartIndicatorCenter = null;
    _dragIndicatorCenter = null;
    _pointerDownGlobalPosition = null;
    _isDragging = false;
    _suppressTap = false;
    if (wasDragging && mounted) setState(() {});
  }

  void _settleToPage(int index) {
    final target = index.clamp(0, _itemCount - 1).toInt();
    widget.onIndexChanged(target);

    // The parent normally starts the page animation from onIndexChanged. Keep a
    // standalone bar usable as well, without starting a second animation when
    // the parent already owns the navigation transition.
    if (!_hasUsablePosition()) return;
    try {
      final position = widget.controller.position;
      if (position.isScrollingNotifier.value) return;
      final page = _readPage();
      if (page == null || (page - target).abs() < 0.001) return;
      unawaited(
        widget.controller.animateToPage(
          target,
          duration: _dragDuration,
          curve: Curves.easeOutCubic,
        ),
      );
    } catch (_) {
      // A controller can detach between the position checks and the call.
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isLight = Theme.of(context).brightness == Brightness.light;
    final background = isLight
        ? AppColors.lightGlassBackground
        : AppColors.glassBackground;
    final border = isLight ? AppColors.lightGlassBorder : AppColors.glassBorder;
    // Keep the active capsule more transparent than the navigation surface so
    // the shared blurred background remains visible.
    final indicatorTintAlpha = isLight ? 0.16 : 0.06;
    final indicatorWashAlpha = isLight ? 0.06 : 0.03;
    final navigationShadow = isLight
        ? Colors.black.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.48);

    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedSlide(
        key: const ValueKey('navigation-visibility-slide'),
        offset: widget.visible ? Offset.zero : const Offset(0, 1.2),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Padding(
          padding: const EdgeInsets.only(left: 28, right: 28, bottom: 26),
          child: SizedBox(
            key: const ValueKey('navigation-frame'),
            height: 54,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // PhysicalModel casts the shadow only outside the pill outline;
                // unlike a translucent fill, it does not tint the bar interior.
                Positioned.fill(
                  child: PhysicalModel(
                    key: const ValueKey('navigation-shadow'),
                    color: Colors.transparent,
                    shadowColor: navigationShadow,
                    elevation: 10,
                    borderRadius: BorderRadius.circular(27),
                    clipBehavior: Clip.none,
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(27),
                    child: _navigationBackdropFilter(
                      sigma: 18,
                      child: DecoratedBox(
                        key: const ValueKey('navigation-background'),
                        decoration: BoxDecoration(
                          color: background,
                          borderRadius: BorderRadius.circular(27),
                          border: Border.all(color: border, width: 0.8),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      _surfaceWidth = constraints.maxWidth;
                      final itemWidth = constraints.maxWidth / _itemCount;
                      return AnimatedBuilder(
                        animation: Listenable.merge([
                          widget.controller,
                          _jellyController,
                          _clickController,
                        ]),
                        builder: (context, child) {
                          final page =
                              (_isDragging
                                      ? (_dragIndicatorPage ??
                                            _pageOrCurrentIndex())
                                      : _pageOrCurrentIndex())
                                  .clamp(0.0, (_itemCount - 1).toDouble());
                          final fraction = page - page.floorToDouble();
                          final transitionProgress = math.sin(
                            math.pi * fraction.clamp(0.0, 1.0),
                          );
                          final visual = _visualProgress();
                          final dragShape = visual.clamp(0.0, 1.0).toDouble();
                          final rebound = (-visual).clamp(0.0, 1.0).toDouble();
                          // ProcessManager leaves an 8dp inset on each side. The
                          // larger capsule gives the drag deformation enough room
                          // to remain visible instead of looking like a thin pill.
                          const indicatorInset = 8.0;
                          final baseWidth = math.max(
                            0.0,
                            itemWidth - indicatorInset * 2,
                          );
                          final clickScale = _clickScale();
                          // Page transitions narrow and flatten the capsule. Drag and
                          // jelly deformation stay separate so they can remain elastic.
                          final transitionNarrow =
                              1 - 0.12 * transitionProgress;
                          final transitionFlatten =
                              1 - 0.04 * transitionProgress;
                          final dragWidth = baseWidth * (1 + 0.42 * dragShape);
                          final animatedWidth =
                              math.max(baseWidth, dragWidth) *
                              transitionNarrow *
                              (1 + 0.50 * rebound) *
                              clickScale.scaleX;
                          // The capsule may widen during a drag, but its
                          // horizontal bounds are always clamped to the complete
                          // tab range. This prevents dragging it outside the bar.
                          final width = math.min(
                            constraints.maxWidth,
                            math.max(
                              1.0,
                              _isDragging
                                  ? dragWidth
                                  : math.min(itemWidth - 2, animatedWidth),
                            ),
                          );
                          // Keep ProcessManager's vertical elastic overhang: the
                          // dragged capsule may become taller than the 54dp bar.
                          // The outer indicator stack uses Clip.none for this.
                          final height = math.max(
                            1.0,
                            (42 + 24 * dragShape - 26 * rebound) *
                                transitionFlatten *
                                clickScale.scaleY,
                          );
                          final requestedCenter =
                              _isDragging && _dragIndicatorCenter != null
                              ? _dragIndicatorCenter!
                              : itemWidth * page + itemWidth / 2;
                          final center = requestedCenter.clamp(
                            width / 2,
                            constraints.maxWidth - width / 2,
                          );
                          final indicatorLeft = center - width / 2;
                          final indicatorTop =
                              (constraints.maxHeight - height) / 2;
                          final indicatorTint = DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withValues(
                                alpha: indicatorTintAlpha,
                              ),
                              borderRadius: BorderRadius.circular(height / 2),
                            ),
                            child: SizedBox(width: width, height: height),
                          );

                          return Stack(
                            key: const ValueKey('navigation-indicator-layer'),
                            clipBehavior: Clip.none,
                            children: [
                              // The navigation background supplies blur for the
                              // resting capsule. Add a second blur only while the
                              // capsule is following a pointer drag.
                              Positioned(
                                left: indicatorLeft,
                                top: indicatorTop,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    height / 2,
                                  ),
                                  child: _isDragging
                                      ? _navigationBackdropFilter(
                                          key: const ValueKey(
                                            'navigation-indicator-backdrop',
                                          ),
                                          sigma: 26,
                                          child: indicatorTint,
                                        )
                                      : indicatorTint,
                                ),
                              ),
                              // A very light foreground wash and outline keep the
                              // active tab readable while leaving the surface
                              // visibly translucent.
                              Positioned(
                                left: indicatorLeft,
                                top: indicatorTop,
                                child: DecoratedBox(
                                  key: const ValueKey('navigation-indicator'),
                                  decoration: BoxDecoration(
                                    color: colors.primaryContainer.withValues(
                                      alpha: indicatorWashAlpha,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      height / 2,
                                    ),
                                    border: Border.all(
                                      color: colors.primary.withValues(
                                        alpha: 0.42,
                                      ),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: SizedBox(width: width, height: height),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
                Positioned.fill(
                  child: Listener(
                    key: const ValueKey('navigation-drag-surface'),
                    behavior: HitTestBehavior.opaque,
                    // Listen to raw pointer events instead of waiting for a
                    // gesture recognizer to win the arena. The navigation surface
                    // is already the top hit-test target, so this keeps the page
                    // and indicator at the exact pointer position every frame.
                    onPointerDown: _handlePointerDown,
                    onPointerMove: _handlePointerMove,
                    onPointerUp: _handlePointerUp,
                    onPointerCancel: _handlePointerCancel,
                    child: Row(
                      children: [
                        for (
                          var index = 0;
                          index < _destinations.length;
                          index++
                        )
                          Expanded(
                            child: _NavigationBarItem(
                              destination: _destinations[index],
                              selected: _currentIndex == index,
                              onTap: () {
                                if (index != _currentIndex) {
                                  _startClickAnimation();
                                  _settleToPage(index);
                                }
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

enum _ClickAnimationMode { none, click, press }

class _NavigationDestination {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavigationDestination({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavigationBarItem extends StatelessWidget {
  final _NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  const _NavigationBarItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = selected
        ? (Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF163B78)
              : colors.onPrimaryContainer)
        : colors.onSurfaceVariant;

    return Semantics(
      key: ValueKey('navigation-item-${destination.label}'),
      button: true,
      selected: selected,
      label: destination.label,
      onTap: onTap,
      child: SizedBox(
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? destination.activeIcon : destination.icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              destination.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
