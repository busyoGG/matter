import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matter/pages/settings/home_background_settings_page.dart';
import 'package:matter/providers/home_background_provider.dart';
import 'package:matter/providers/home_background_storage.dart';

class _NoopStorage implements HomeBackgroundStorage {
  @override
  Future<String> save(Uint8List bytes, {required String extension}) async =>
      'unused';

  @override
  Future<void> delete(String path) async {}
}

void main() {
  testWidgets('shows shared light and dark background entries', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeBackgroundProvider.overrideWith(
            () => HomeBackgroundNotifier(
              preferences: preferences,
              storage: _NoopStorage(),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeBackgroundSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('首页背景'), findsOneWidget);
    expect(find.text('浅色模式背景'), findsOneWidget);
    expect(find.text('深色模式背景'), findsOneWidget);
    expect(find.byIcon(Icons.photo_library_outlined), findsNWidgets(2));
    expect(find.byType(Slider), findsNWidgets(3));
    expect(find.byType(SwitchListTile), findsOneWidget);
    expect(find.byIcon(Icons.delete_outline_rounded), findsNothing);
  });

  testWidgets('loads and persists background tuning settings', (tester) async {
    SharedPreferences.setMockInitialValues({
      homeBackgroundOpacityPreferenceKey: 0.45,
      homeBackgroundBlurPreferenceKey: 12.0,
      homeBackgroundDarkenEnabledPreferenceKey: true,
      homeBackgroundDarkenStrengthPreferenceKey: 0.6,
    });
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeBackgroundProvider.overrideWith(
            () => HomeBackgroundNotifier(
              preferences: preferences,
              storage: _NoopStorage(),
            ),
          ),
        ],
        child: const MaterialApp(home: HomeBackgroundSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final sliders = tester.widgetList<Slider>(find.byType(Slider)).toList();
    expect(sliders[0].value, closeTo(0.45, 0.001));
    expect(sliders[1].value, 12.0);
    expect(sliders[2].value, closeTo(0.6, 0.001));
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.drag(find.byType(Slider).at(0), const Offset(80, 0));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      preferences.getDouble(homeBackgroundOpacityPreferenceKey),
      isNot(0.45),
    );
  });
}
