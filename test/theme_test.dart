import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/theme/app_theme.dart';
import 'package:matter/widgets/app_card.dart';
import 'package:matter/widgets/soft_superellipse_border.dart';

void _expectSuperellipse(ShapeBorder? shape) {
  expect(shape, isA<SoftSuperellipseBorder>());
  expect(
    (shape! as SoftSuperellipseBorder).exponent,
    SoftSuperellipseBorder.defaultExponent,
  );
}

Material _appCardMaterial(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (widget) => widget is Material && widget.shape is SoftSuperellipseBorder,
  );
  expect(finder, findsOneWidget);
  return tester.widget<Material>(finder);
}

void main() {
  test('defines distinct light and dark theme data', () {
    expect(AppTheme.lightTheme.brightness, Brightness.light);
    expect(AppTheme.darkTheme.brightness, Brightness.dark);
    expect(
      AppTheme.lightTheme.scaffoldBackgroundColor,
      AppColors.lightBackground,
    );
    expect(AppTheme.darkTheme.scaffoldBackgroundColor, AppColors.background);
    expect(AppTheme.lightTheme.cardTheme.color, AppColors.lightSurface);
    expect(AppTheme.darkTheme.cardTheme.color, AppColors.surface);
    _expectSuperellipse(AppTheme.lightTheme.cardTheme.shape);
    _expectSuperellipse(AppTheme.darkTheme.cardTheme.shape);
    expect(
      AppTheme.lightTheme.colorScheme.surfaceContainerLow,
      isNot(AppColors.surfaceElevated),
    );
    expect(
      AppTheme.lightTheme.colorScheme.surfaceContainerLow,
      const Color(0xFFF1F5F3),
    );
    expect(AppTheme.lightTheme.colorScheme.onPrimary, Colors.white);
    expect(AppTheme.darkTheme.colorScheme.onPrimary, Colors.white);
    expect(
      AppTheme.darkTheme.colorScheme.surfaceContainerLow,
      AppColors.surfaceElevated,
    );
    expect(
      AppTheme.lightTheme.dividerTheme.color,
      AppTheme.lightTheme.colorScheme.outlineVariant,
    );
    expect(
      AppTheme.darkTheme.dividerTheme.color,
      AppTheme.darkTheme.colorScheme.outlineVariant,
    );
    expect(AppTheme.lightTheme.dividerTheme.indent, isNull);
    expect(AppTheme.darkTheme.dividerTheme.indent, isNull);
  });

  testWidgets('AppCard uses the active theme surface in both modes', (
    tester,
  ) async {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        Theme(
          data: theme,
          child: const AppCard(child: SizedBox(width: 20, height: 20)),
        ),
      );
      final material = _appCardMaterial(tester);
      expect(material.color, theme.colorScheme.surface);
      _expectSuperellipse(material.shape);
    }
  });
}
