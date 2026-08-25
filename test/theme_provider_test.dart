import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('loads stored theme mode and persists updates', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(preferences: preferences),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(themeModeProvider.notifier).load();
    expect(container.read(themeModeProvider), ThemeMode.dark);

    await container
        .read(themeModeProvider.notifier)
        .setThemeMode(ThemeMode.light);
    expect(container.read(themeModeProvider), ThemeMode.light);
    expect(preferences.getString(themeModePreferenceKey), 'light');
  });

  test('falls back to system for missing or unknown values', () async {
    for (final value in [null, 'sepia']) {
      final initialValues = <String, Object>{};
      if (value != null) initialValues[themeModePreferenceKey] = value;
      SharedPreferences.setMockInitialValues(initialValues);
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [
          themeModeProvider.overrideWith(
            () => ThemeModeNotifier(preferences: preferences),
          ),
        ],
      );
      await container.read(themeModeProvider.notifier).load();
      expect(container.read(themeModeProvider), ThemeMode.system);
      container.dispose();
    }
  });

  test('reads every stored mode', () {
    expect(themeModeFromStorage('light'), ThemeMode.light);
    expect(themeModeFromStorage('dark'), ThemeMode.dark);
    expect(themeModeFromStorage('system'), ThemeMode.system);
    expect(themeModeToStorage(ThemeMode.light), 'light');
    expect(themeModeToStorage(ThemeMode.dark), 'dark');
    expect(themeModeToStorage(ThemeMode.system), 'system');
  });

  test('uses an injected initial mode without async replacement', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
    final preferences = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        themeModeProvider.overrideWith(
          () => ThemeModeNotifier(
            preferences: preferences,
            initialMode: ThemeMode.light,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(themeModeProvider), ThemeMode.light);
  });

  test('has user-facing labels for all modes', () {
    expect(themeModeLabel(ThemeMode.light), '浅色');
    expect(themeModeLabel(ThemeMode.dark), '深色');
    expect(themeModeLabel(ThemeMode.system), '跟随系统');
  });
}
