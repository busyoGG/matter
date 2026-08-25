import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeModePreferenceKey = 'theme_mode';

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeModeNotifier({this._preferences, this._initialMode});

  final SharedPreferences? _preferences;
  final ThemeMode? _initialMode;
  Future<void>? _loadFuture;
  Future<void> _writeTail = Future.value();
  bool _hasExplicitMode = false;

  @override
  ThemeMode build() {
    if (_initialMode == null) unawaited(load());
    return _initialMode ?? ThemeMode.system;
  }

  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      if (_hasExplicitMode) return;
      final storedMode = themeModeFromStorage(
        preferences.getString(themeModePreferenceKey),
      );
      // Let the initial build finish before applying an asynchronously loaded
      // value, including when a test injects an already-resolved preference.
      await Future<void>.delayed(Duration.zero);
      if (ref.mounted) state = storedMode;
    } catch (_) {
      // The system default remains usable when preferences are unavailable.
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    final previousMode = state;
    _hasExplicitMode = true;
    state = mode;
    final operation = _writeTail.then((_) async {
      final preferences = _preferences ?? await SharedPreferences.getInstance();
      await preferences.setString(
        themeModePreferenceKey,
        themeModeToStorage(mode),
      );
    });
    _writeTail = operation.catchError((_) {});
    return operation.catchError((error, stackTrace) {
      if (ref.mounted && state == mode) state = previousMode;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }
}

ThemeMode themeModeFromStorage(String? value) => switch (value) {
  'light' => ThemeMode.light,
  'dark' => ThemeMode.dark,
  'system' => ThemeMode.system,
  _ => ThemeMode.system,
};

String themeModeToStorage(ThemeMode mode) => switch (mode) {
  ThemeMode.light => 'light',
  ThemeMode.dark => 'dark',
  ThemeMode.system => 'system',
};

String themeModeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.light => '浅色',
  ThemeMode.dark => '深色',
  ThemeMode.system => '跟随系统',
};
