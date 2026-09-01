import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/theme/app_theme.dart';
import 'package:matter/widgets/app_card.dart';
import 'package:matter/widgets/avatar_info_row.dart';
import 'package:matter/widgets/home_background.dart';
import 'package:matter/widgets/soft_superellipse_border.dart';

Material _cardMaterial(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is Material && widget.shape is SoftSuperellipseBorder,
  );
  expect(finder, findsOneWidget);
  return tester.widget<Material>(finder);
}

void _expectCardShape(Material material) {
  expect(material.shape, isA<SoftSuperellipseBorder>());
  expect(
    (material.shape! as SoftSuperellipseBorder).exponent,
    SoftSuperellipseBorder.defaultExponent,
  );
}

void main() {
  group('AppCard', () {
    testWidgets('renders its child with a superellipse surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppCard(child: Text('Hello'))),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
      _expectCardShape(_cardMaterial(tester));
    });

    testWidgets('uses the default surface color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(
            body: AppCard(child: SizedBox(width: 100, height: 100)),
          ),
        ),
      );

      final material = _cardMaterial(tester);
      expect(material.color, AppColors.surface);
      _expectCardShape(material);
    });

    testWidgets('uses a custom color when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              color: Colors.red,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final material = _cardMaterial(tester);
      expect(material.color, Colors.red);
      _expectCardShape(material);
    });

    testWidgets('uses one grouped backdrop filter inside a home scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeBackgroundScope(
            enabled: true,
            child: BackdropGroup(
              child: Scaffold(
                body: const AppCard(child: SizedBox(width: 100, height: 100)),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropGroup), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      expect(_cardMaterial(tester).color, Colors.transparent);
      expect(find.byType(ClipPath), findsOneWidget);
    });

    testWidgets('keeps the opaque card path when background is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: HomeBackgroundScope(
            enabled: false,
            child: Scaffold(
              body: const AppCard(child: SizedBox(width: 100, height: 100)),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(_cardMaterial(tester).color, AppColors.surface);
    });

    testWidgets('skips the backdrop filter when blur is disabled', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomeBackgroundScope(
            enabled: true,
            cardBlurSigma: 0,
            child: BackdropGroup(
              child: Scaffold(
                body: const AppCard(child: SizedBox(width: 100, height: 100)),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      expect(_cardMaterial(tester).color, Colors.transparent);
    });

    testWidgets('uses the surface color for a default list card', (
      tester,
    ) async {
      const cardKey = ValueKey('default-list-card');
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: AvatarInfoRow(
              avatar: const SizedBox(width: 40, height: 40),
              cardKey: cardKey,
              child: const Text('Room'),
            ),
          ),
        ),
      );

      expect(
        tester.widget<Material>(find.byKey(cardKey)).color,
        AppColors.surface,
      );
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap me'));
      expect(tapped, isTrue);
    });
  });
}
