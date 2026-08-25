import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/theme/app_theme.dart';
import 'package:matter/widgets/app_card.dart';

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
      final cardContainer = find.ancestor(
        of: find.byType(SizedBox),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(cardContainer);
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.color, theme.colorScheme.surface);
    }
  });
}
