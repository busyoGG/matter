import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/theme/app_theme.dart';
import 'package:matter/widgets/floating_bottom_navigation_bar.dart';

class _NavigationHarness extends StatefulWidget {
  final PageController controller;
  final ValueChanged<int>? onIndexChanged;

  const _NavigationHarness({required this.controller, this.onIndexChanged});

  @override
  State<_NavigationHarness> createState() => _NavigationHarnessState();
}

class _NavigationHarnessState extends State<_NavigationHarness> {
  int currentIndex = 0;

  void _onIndexChanged(int index) {
    setState(() => currentIndex = index);
    widget.onIndexChanged?.call(index);
    if (widget.controller.hasClients) {
      widget.controller.animateToPage(
        index,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: widget.controller,
        children: const [
          ColoredBox(color: Colors.red),
          ColoredBox(color: Colors.green),
          ColoredBox(color: Colors.blue),
          ColoredBox(color: Colors.yellow),
        ],
      ),
      bottomNavigationBar: FloatingBottomNavigationBar(
        controller: widget.controller,
        currentIndex: currentIndex,
        onIndexChanged: _onIndexChanged,
      ),
    );
  }
}

Widget _app({required Widget child, Brightness brightness = Brightness.light}) {
  return MaterialApp(
    theme: brightness == Brightness.light
        ? AppTheme.lightTheme
        : AppTheme.darkTheme,
    home: child,
  );
}

void main() {
  testWidgets('tapping an unselected tab calls back and changes page', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var selectedIndex = -1;

    await tester.pumpWidget(
      _app(
        child: _NavigationHarness(
          controller: controller,
          onIndexChanged: (index) => selectedIndex = index,
        ),
      ),
    );

    await tester.tap(find.text('空间'));
    await tester.pumpAndSettle();

    expect(selectedIndex, 1);
    expect(controller.page, closeTo(1, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('navigation frame uses the ProcessManager geometry', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(child: _NavigationHarness(controller: controller)),
    );

    final frame = find.byKey(const ValueKey('navigation-frame'));
    final shadow = find.byKey(const ValueKey('navigation-shadow'));
    final background = find.byKey(const ValueKey('navigation-background'));
    final indicatorBackdrop = find.byKey(
      const ValueKey('navigation-indicator-backdrop'),
    );
    final indicatorLayer = tester.widget<Stack>(
      find.byKey(const ValueKey('navigation-indicator-layer')),
    );
    expect(tester.getSize(frame).height, closeTo(54, 0.001));
    expect(tester.getSize(frame).width, closeTo(744, 0.001));
    final shadowModel = tester.widget<PhysicalModel>(shadow);
    expect(shadowModel.elevation, greaterThan(0));
    expect(shadowModel.shadowColor.a, greaterThan(0));
    expect(shadowModel.borderRadius, BorderRadius.circular(27));

    final selectedItem = find.byKey(const ValueKey('navigation-item-聊天'));
    final selectedIcon = tester.widget<Icon>(
      find.descendant(of: selectedItem, matching: find.byType(Icon)),
    );
    final selectedLabel = tester.widget<Text>(
      find.descendant(of: selectedItem, matching: find.byType(Text)),
    );
    expect(selectedIcon.color, const Color(0xFF163B78));
    expect(selectedLabel.style?.color, const Color(0xFF163B78));

    final backgroundBox = tester.widget<DecoratedBox>(background);
    final decoration = backgroundBox.decoration as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(27));
    final navigationBackdrop = find.ancestor(
      of: background,
      matching: find.byType(BackdropFilter),
    );
    expect(navigationBackdrop, findsOneWidget);
    final navigationBackdropFilter = tester.widget<BackdropFilter>(
      navigationBackdrop,
    );
    expect(navigationBackdropFilter.filter, isNull);
    expect(
      navigationBackdropFilter.filterConfig?.debugShortDescription,
      'blur(18.0, 18.0, clamp, bounded)',
    );
    expect(
      find.byKey(const ValueKey('navigation-indicator-layer')),
      findsOneWidget,
    );
    expect(indicatorBackdrop, findsNothing);
    expect(indicatorLayer.children[0], isA<Positioned>());
    expect((indicatorLayer.children[0] as Positioned).child, isA<ClipRRect>());
    final indicatorTint = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byKey(const ValueKey('navigation-indicator-layer')),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    final tintDecoration = indicatorTint.decoration as BoxDecoration;
    expect(tintDecoration.color?.a, lessThan(1));
    final foreground =
        (indicatorLayer.children[1] as Positioned).child as DecoratedBox;
    final foregroundDecoration = foreground.decoration as BoxDecoration;
    expect(foregroundDecoration.color?.a, lessThan(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('hidden navigation bar keeps layout and blocks taps', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var callbackCount = 0;

    await tester.pumpWidget(
      _app(
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: FloatingBottomNavigationBar(
            controller: controller,
            currentIndex: 0,
            onIndexChanged: (_) => callbackCount++,
            visible: false,
          ),
        ),
      ),
    );
    await tester.pump();

    final frame = find.byKey(const ValueKey('navigation-frame'));
    final slide = find.byKey(const ValueKey('navigation-visibility-slide'));
    final ignorePointer = tester.widget<IgnorePointer>(
      find.ancestor(of: frame, matching: find.byType(IgnorePointer)).first,
    );
    expect(tester.getSize(frame).height, closeTo(54, 0.001));
    expect(tester.widget<AnimatedSlide>(slide).offset, const Offset(0, 1.2));
    expect(ignorePointer.ignoring, isTrue);

    await tester.tapAt(tester.getCenter(frame));
    await tester.pump();
    expect(callbackCount, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'indicator and selected semantics remain available during animation',
    (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(child: _NavigationHarness(controller: controller)),
      );
      final semantics = tester.ensureSemantics();

      expect(
        find.byKey(const ValueKey('navigation-indicator')),
        findsOneWidget,
      );
      expect(
        tester
            .getSemantics(find.byKey(const ValueKey('navigation-item-聊天')))
            .flagsCollection
            .isSelected,
        Tristate.isTrue,
      );

      unawaited(
        controller.animateToPage(
          2,
          duration: const Duration(milliseconds: 240),
          curve: Curves.linear,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const ValueKey('navigation-indicator')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('navigation-item-聊天')), findsOneWidget);
      semantics.dispose();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('page transition narrows and slightly flattens indicator', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(child: _NavigationHarness(controller: controller)),
    );
    final indicator = find.byKey(const ValueKey('navigation-indicator'));
    final indicatorBackdrop = find.byKey(
      const ValueKey('navigation-indicator-backdrop'),
    );
    final baseSize = tester.getSize(indicator);

    await tester.pump();
    unawaited(
      controller.animateToPage(
        1,
        duration: const Duration(milliseconds: 240),
        curve: Curves.linear,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final animatedSize = tester.getSize(indicator);
    expect(animatedSize.width, lessThan(baseSize.width));
    expect(animatedSize.height, lessThan(baseSize.height));
    expect(indicatorBackdrop, findsNothing);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('indicator elastically changes size and settles back', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(child: _NavigationHarness(controller: controller)),
    );
    final indicator = find.byKey(const ValueKey('navigation-indicator'));
    final indicatorBackdrop = find.byKey(
      const ValueKey('navigation-indicator-backdrop'),
    );
    final baseSize = tester.getSize(indicator);
    expect(indicatorBackdrop, findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('空间')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(indicator, findsOneWidget);
    expect(indicatorBackdrop, findsNothing);
    final pressedSize = tester.getSize(indicator);
    expect(pressedSize, isNot(equals(baseSize)));
    expect(pressedSize.width, lessThan(baseSize.width));

    await gesture.up();
    await tester.pump();
    expect(indicatorBackdrop, findsNothing);
    await tester.pump(const Duration(milliseconds: 50));

    final settlingSize = tester.getSize(indicator);
    expect(settlingSize, isNot(equals(baseSize)));
    expect(settlingSize.width, lessThan(baseSize.width));
    expect(settlingSize.height, lessThan(baseSize.height));

    await tester.pumpAndSettle();

    expect(controller.page, closeTo(1, 0.001));
    final settledSize = tester.getSize(indicator);
    expect(settledSize.width, closeTo(baseSize.width, 0.001));
    expect(settledSize.height, closeTo(baseSize.height, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('indicator follows slot geometry through drag and jelly phases', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(child: _NavigationHarness(controller: controller)),
    );
    final surface = find.byKey(const ValueKey('navigation-drag-surface'));
    final frame = find.byKey(const ValueKey('navigation-frame'));
    final indicator = find.byKey(const ValueKey('navigation-indicator'));
    final indicatorBackdrop = find.byKey(
      const ValueKey('navigation-indicator-backdrop'),
    );
    final frameRect = tester.getRect(frame);
    final surfaceRect = tester.getRect(surface);
    final baseRect = tester.getRect(indicator);
    final slotWidth = surfaceRect.width / 4;

    expect(baseRect.width, greaterThan(44));
    expect(baseRect.left, greaterThan(surfaceRect.left));
    expect(baseRect.right, lessThan(surfaceRect.left + slotWidth));
    expect(baseRect.top, greaterThan(surfaceRect.top));
    expect(baseRect.bottom, lessThan(surfaceRect.bottom));

    final gesture = await tester.startGesture(tester.getCenter(surface));
    await tester.pump();
    const firstDrag = 80.0;
    await gesture.moveBy(const Offset(firstDrag, 0));
    await tester.pump();

    expect(controller.page, closeTo(firstDrag / slotWidth, 0.001));
    expect(indicatorBackdrop, findsOneWidget);
    final indicatorBackdropFilter = tester.widget<BackdropFilter>(
      indicatorBackdrop,
    );
    expect(indicatorBackdropFilter.filter, isNull);
    expect(
      indicatorBackdropFilter.filterConfig?.debugShortDescription,
      'blur(26.0, 26.0, clamp, bounded)',
    );
    final firstDragRect = tester.getRect(indicator);
    expect(firstDragRect.center.dx, closeTo(baseRect.center.dx + firstDrag, 1));
    expect(firstDragRect.width, greaterThan(baseRect.width));
    expect(firstDragRect.height, greaterThan(baseRect.height));

    await gesture.moveBy(const Offset(-firstDrag, 0));
    await tester.pump();
    final originDragRect = tester.getRect(indicator);
    // At the first tab the enlarged capsule is clamped to the left edge,
    // so its center may shift right while the whole shape stays in the bar.
    expect(originDragRect.left, greaterThanOrEqualTo(frameRect.left));
    expect(originDragRect.right, lessThanOrEqualTo(frameRect.right));
    expect(originDragRect.width, greaterThan(baseRect.width));
    expect(originDragRect.height, greaterThan(baseRect.height));

    await gesture.moveBy(const Offset(120, 0));
    await tester.pump();
    final dragRect = tester.getRect(indicator);
    expect(dragRect.width, greaterThanOrEqualTo(baseRect.width));
    expect(dragRect.height, greaterThan(baseRect.height));
    expect(dragRect.top, lessThan(frameRect.top));
    expect(dragRect.bottom, greaterThan(frameRect.bottom));
    expect(dragRect.left, greaterThanOrEqualTo(frameRect.left));
    expect(dragRect.right, lessThanOrEqualTo(frameRect.right));
    expect(dragRect.center.dx, greaterThan(baseRect.center.dx));

    await gesture.up();
    await tester.pump();
    expect(indicatorBackdrop, findsNothing);
    await tester.pump(const Duration(milliseconds: 180));

    final reboundRect = tester.getRect(indicator);
    expect(reboundRect.width, greaterThan(baseRect.width));
    expect(reboundRect.height, lessThan(baseRect.height));

    await tester.pumpAndSettle();
    final settledRect = tester.getRect(indicator);
    expect(settledRect.width, closeTo(baseRect.width, 0.001));
    expect(settledRect.height, closeTo(baseRect.height, 0.001));
    expect(controller.page, closeTo(1, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('click scale has separate three-stage geometry', (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _app(child: _NavigationHarness(controller: controller)),
    );
    final indicator = find.byKey(const ValueKey('navigation-indicator'));
    final indicatorBackdrop = find.byKey(
      const ValueKey('navigation-indicator-backdrop'),
    );
    final baseSize = tester.getSize(indicator);
    expect(indicatorBackdrop, findsNothing);

    await tester.tap(find.text('空间'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(indicatorBackdrop, findsNothing);
    final firstStage = tester.getSize(indicator);
    expect(firstStage.height, lessThan(baseSize.height));

    await tester.pump(const Duration(milliseconds: 100));
    expect(indicatorBackdrop, findsNothing);
    final secondStage = tester.getSize(indicator);
    expect(secondStage.height, greaterThan(firstStage.height));
    expect(secondStage.height, greaterThanOrEqualTo(baseSize.height));

    await tester.pumpAndSettle();
    final settledSize = tester.getSize(indicator);
    expect(settledSize.width, closeTo(baseSize.width, 0.001));
    expect(settledSize.height, closeTo(baseSize.height, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping the current tab only presses the indicator', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var callbackCount = 0;

    await tester.pumpWidget(
      _app(
        child: _NavigationHarness(
          controller: controller,
          onIndexChanged: (_) => callbackCount++,
        ),
      ),
    );
    final indicator = find.byKey(const ValueKey('navigation-indicator'));
    final baseSize = tester.getSize(indicator);

    final gesture = await tester.startGesture(
      tester.getCenter(find.text('聊天')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.getSize(indicator).width, lessThan(baseSize.width));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(callbackCount, 0);
    expect(tester.getSize(indicator).width, closeTo(baseSize.width, 0.001));
    expect(controller.page, closeTo(0, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('horizontal drag snaps to a legal page', (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var selectedIndex = -1;

    await tester.pumpWidget(
      _app(
        child: _NavigationHarness(
          controller: controller,
          onIndexChanged: (index) => selectedIndex = index,
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('navigation-drag-surface')),
      const Offset(500, 0),
    );
    await tester.pumpAndSettle();

    expect(selectedIndex, 3);
    expect(controller.page, inInclusiveRange(0, 3));
    expect(controller.page, closeTo(3, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('one continuous drag can cross multiple pages', (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var selectedIndex = -1;

    await tester.pumpWidget(
      _app(
        child: _NavigationHarness(
          controller: controller,
          onIndexChanged: (index) => selectedIndex = index,
        ),
      ),
    );

    final surface = find.byKey(const ValueKey('navigation-drag-surface'));
    final surfaceRect = tester.getRect(surface);
    final gesture = await tester.startGesture(surfaceRect.center);
    await tester.pump();
    final tabWidth = surfaceRect.width / 4;
    await gesture.moveBy(Offset(tabWidth * 2.6, 0));
    await tester.pump();

    expect(controller.page, closeTo(2.6, 0.001));
    final baseIndicatorCenter = surfaceRect.left + tabWidth / 2;
    expect(
      tester
          .getRect(find.byKey(const ValueKey('navigation-indicator')))
          .center
          .dx,
      closeTo(baseIndicatorCenter + tabWidth * 2.6, 1),
    );

    await gesture.up();
    await tester.pumpAndSettle();

    expect(selectedIndex, 3);
    expect(controller.page, closeTo(3, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('drag can return from the second page to the first', (
    tester,
  ) async {
    final controller = PageController(initialPage: 1);
    addTearDown(controller.dispose);
    var selectedIndex = -1;

    await tester.pumpWidget(
      _app(
        child: _NavigationHarness(
          controller: controller,
          onIndexChanged: (index) => selectedIndex = index,
        ),
      ),
    );
    await tester.pump();

    await tester.drag(
      find.byKey(const ValueKey('navigation-drag-surface')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();

    expect(selectedIndex, 0);
    expect(controller.page, closeTo(0, 0.001));
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unconnected controller is safe', (tester) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    var selectedIndex = -1;

    await tester.pumpWidget(
      _app(
        child: Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: FloatingBottomNavigationBar(
            controller: controller,
            currentIndex: 0,
            onIndexChanged: (index) => selectedIndex = index,
          ),
        ),
      ),
    );

    await tester.tap(find.text('空间'));
    await tester.pump();

    expect(selectedIndex, 1);
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets('${brightness.name} labels are visible', (tester) async {
      final controller = PageController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          brightness: brightness,
          child: _NavigationHarness(controller: controller),
        ),
      );

      for (final label in ['聊天', '空间', '通讯录', '设置']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
