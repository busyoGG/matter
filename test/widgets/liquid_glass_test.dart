import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/widgets/liquid_glass.dart';
import 'package:matter/widgets/soft_superellipse_border.dart';

Material _glassMaterial(WidgetTester tester, Finder ancestor) {
  final materialFinder = find.descendant(
    of: ancestor,
    matching: find.byType(Material),
  );
  expect(materialFinder, findsOneWidget);
  return tester.widget<Material>(materialFinder);
}

void _expectSuperellipse(Material material) {
  expect(material.shape, isA<SoftSuperellipseBorder>());
  expect(
    (material.shape! as SoftSuperellipseBorder).exponent,
    SoftSuperellipseBorder.defaultExponent,
  );
}

void main() {
  group('LiquidGlassContainer', () {
    testWidgets('renders its child inside a clipped backdrop blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: LiquidGlassContainer(child: Text('Glass'))),
        ),
      );

      expect(find.text('Glass'), findsOneWidget);
      expect(find.byType(ClipPath), findsOneWidget);
      expect(
        tester.widget<ClipPath>(find.byType(ClipPath)).clipper,
        isA<ShapeBorderClipper>(),
      );
      expect(find.byType(BackdropFilter), findsOneWidget);
      _expectSuperellipse(_glassMaterial(tester, find.byType(BackdropFilter)));
    });

    testWidgets('casts a superellipse shadow outside the glass clip', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidGlassContainer(
              elevation: 4,
              child: SizedBox(width: 100, height: 60),
            ),
          ),
        ),
      );

      final physicalShape = tester.widget<PhysicalShape>(
        find.byKey(const ValueKey('liquid-glass-shadow')),
      );
      expect(physicalShape.clipper, isA<ShapeBorderClipper>());
      expect(physicalShape.elevation, 4);
      expect(physicalShape.clipBehavior, Clip.antiAlias);
      expect(physicalShape.shadowColor.a, greaterThan(0));
      final stack = tester.widget<Stack>(
        find.ancestor(
          of: find.byKey(const ValueKey('liquid-glass-shadow')),
          matching: find.byType(Stack),
        ),
      );
      expect(stack.clipBehavior, Clip.none);

      expect(find.byType(BackdropFilter), findsOneWidget);
      _expectSuperellipse(_glassMaterial(tester, find.byType(BackdropFilter)));
    });

    testWidgets('applies custom margin and padding', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidGlassContainer(
              margin: EdgeInsets.all(8),
              padding: EdgeInsets.all(4),
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final outerPadding = tester.widget<Padding>(find.byType(Padding).first);
      expect(outerPadding.padding, const EdgeInsets.all(8));

      final innerPadding = tester.widget<Padding>(
        find.descendant(
          of: find.byType(BackdropFilter),
          matching: find.byType(Padding),
        ),
      );
      expect(innerPadding.padding, const EdgeInsets.all(4));
    });

    testWidgets('can render a glass surface without backdrop blur', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiquidGlassContainer(blurSigma: 0, child: Text('Surface')),
          ),
        ),
      );

      expect(find.text('Surface'), findsOneWidget);
      expect(find.byType(ClipPath), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
      _expectSuperellipse(_glassMaterial(tester, find.byType(ClipPath)));
    });
  });
}
