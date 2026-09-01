import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_background_storage.dart';

const homeBackgroundPreferenceKey = 'home_background_path';
const homeBackgroundDarkPreferenceKey = 'home_background_path_dark';
const homeBackgroundOpacityPreferenceKey = 'home_background_opacity';
const homeBackgroundBlurPreferenceKey = 'home_background_blur_sigma';
const homeBackgroundDarkenEnabledPreferenceKey =
    'home_background_darken_enabled';
const homeBackgroundDarkenStrengthPreferenceKey =
    'home_background_darken_strength';

const homeBackgroundDefaultOpacity = 1.0;
const homeBackgroundDefaultBlurSigma = 18.0;
const homeBackgroundDefaultDarkenEnabled = false;
const homeBackgroundDefaultDarkenStrength = 0.30;
const homeBackgroundMaxBlurSigma = 32.0;

const _legacyHomeBackgroundPreferenceKeys = [
  'home_background_path_chat',
  'home_background_path_spaces',
  'home_background_path_contacts',
  'home_background_path_settings',
];

const _unset = Object();

enum HomeBackgroundVariant { light, dark }

class HomeBackgroundState {
  final String? path;
  final String? darkPath;
  final double imageOpacity;
  final double cardBlurSigma;
  final bool darkenEnabled;
  final double darkenStrength;

  const HomeBackgroundState({
    this.path,
    this.darkPath,
    this.imageOpacity = homeBackgroundDefaultOpacity,
    this.cardBlurSigma = homeBackgroundDefaultBlurSigma,
    this.darkenEnabled = homeBackgroundDefaultDarkenEnabled,
    this.darkenStrength = homeBackgroundDefaultDarkenStrength,
  });

  String? pathFor({required bool dark}) => dark ? darkPath ?? path : path;

  HomeBackgroundState copyWith({
    Object? path = _unset,
    Object? darkPath = _unset,
    double? imageOpacity,
    double? cardBlurSigma,
    bool? darkenEnabled,
    double? darkenStrength,
  }) => HomeBackgroundState(
    path: identical(path, _unset) ? this.path : path as String?,
    darkPath: identical(darkPath, _unset) ? this.darkPath : darkPath as String?,
    imageOpacity: imageOpacity ?? this.imageOpacity,
    cardBlurSigma: cardBlurSigma ?? this.cardBlurSigma,
    darkenEnabled: darkenEnabled ?? this.darkenEnabled,
    darkenStrength: darkenStrength ?? this.darkenStrength,
  );

  HomeBackgroundState withPath(String? path) => copyWith(path: path);

  HomeBackgroundState withDarkPath(String? path) => copyWith(darkPath: path);
}

final homeBackgroundProvider =
    NotifierProvider<HomeBackgroundNotifier, HomeBackgroundState>(
      HomeBackgroundNotifier.new,
    );

class HomeBackgroundNotifier extends Notifier<HomeBackgroundState> {
  HomeBackgroundNotifier({this.preferences, this.storage});

  final SharedPreferences? preferences;
  final HomeBackgroundStorage? storage;
  Future<void>? _loadFuture;
  Future<void> _writeTail = Future.value();
  bool _hasExplicitState = false;

  HomeBackgroundStorage get _backgroundStorage =>
      storage ?? createHomeBackgroundStorage();

  @override
  HomeBackgroundState build() {
    unawaited(load());
    return const HomeBackgroundState();
  }

  Future<void> load() => _loadFuture ??= _load();

  String? _readPath(SharedPreferences prefs, String key) {
    final value = prefs.getString(key);
    return value == null || value.isEmpty ? null : value;
  }

  double _readDouble(
    SharedPreferences prefs,
    String key,
    double fallback, {
    required double max,
  }) {
    final value = prefs.get(key);
    if (value is! num || !value.isFinite) return fallback;
    return value.toDouble().clamp(0.0, max).toDouble();
  }

  Future<void> _load() async {
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      if (_hasExplicitState) return;
      var path = _readPath(prefs, homeBackgroundPreferenceKey);
      if (path == null) {
        for (final legacyKey in _legacyHomeBackgroundPreferenceKeys) {
          final legacyPath = _readPath(prefs, legacyKey);
          if (legacyPath != null) {
            path = legacyPath;
            final migrated = await prefs.setString(
              homeBackgroundPreferenceKey,
              legacyPath,
            );
            if (migrated) {
              for (final key in _legacyHomeBackgroundPreferenceKeys) {
                await prefs.remove(key);
              }
            }
            break;
          }
        }
      }
      final nextState = HomeBackgroundState(
        path: path,
        darkPath: _readPath(prefs, homeBackgroundDarkPreferenceKey),
        imageOpacity: _readDouble(
          prefs,
          homeBackgroundOpacityPreferenceKey,
          homeBackgroundDefaultOpacity,
          max: 1.0,
        ),
        cardBlurSigma: _readDouble(
          prefs,
          homeBackgroundBlurPreferenceKey,
          homeBackgroundDefaultBlurSigma,
          max: homeBackgroundMaxBlurSigma,
        ),
        darkenEnabled:
            prefs.get(homeBackgroundDarkenEnabledPreferenceKey) is bool
            ? prefs.getBool(homeBackgroundDarkenEnabledPreferenceKey)!
            : homeBackgroundDefaultDarkenEnabled,
        darkenStrength: _readDouble(
          prefs,
          homeBackgroundDarkenStrengthPreferenceKey,
          homeBackgroundDefaultDarkenStrength,
          max: 1.0,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      if (ref.mounted && !_hasExplicitState) state = nextState;
    } catch (_) {
      // The theme background remains usable when preferences are unavailable.
    }
  }

  String _preferenceKey(HomeBackgroundVariant variant) =>
      variant == HomeBackgroundVariant.dark
      ? homeBackgroundDarkPreferenceKey
      : homeBackgroundPreferenceKey;

  String? _pathForVariant(
    HomeBackgroundState value,
    HomeBackgroundVariant variant,
  ) => variant == HomeBackgroundVariant.dark ? value.darkPath : value.path;

  HomeBackgroundState _stateWithPath(
    HomeBackgroundState value,
    HomeBackgroundVariant variant,
    String? path,
  ) => variant == HomeBackgroundVariant.dark
      ? value.withDarkPath(path)
      : value.withPath(path);

  Future<void> setBackground(
    Uint8List bytes, {
    String extension = 'jpg',
    HomeBackgroundVariant variant = HomeBackgroundVariant.light,
  }) {
    final previousPath = _pathForVariant(state, variant);
    _hasExplicitState = true;
    final operation = _writeTail.then((_) async {
      final nextPath = await _backgroundStorage.save(
        bytes,
        extension: extension,
      );
      try {
        final prefs = preferences ?? await SharedPreferences.getInstance();
        final written = await prefs.setString(
          _preferenceKey(variant),
          nextPath,
        );
        if (!written) throw StateError('首页背景路径保存失败');
      } catch (error, stackTrace) {
        try {
          await _backgroundStorage.delete(nextPath);
        } catch (_) {}
        Error.throwWithStackTrace(error, stackTrace);
      }
      if (previousPath != null && previousPath != nextPath) {
        try {
          await _backgroundStorage.delete(previousPath);
        } catch (_) {
          // A valid new path is safer than failing the visible update because
          // an old orphaned file could not be removed.
        }
      }
      if (ref.mounted) state = _stateWithPath(state, variant, nextPath);
    });
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> clearBackground({
    HomeBackgroundVariant variant = HomeBackgroundVariant.light,
  }) {
    final previousPath = _pathForVariant(state, variant);
    _hasExplicitState = true;
    final key = _preferenceKey(variant);
    final operation = _writeTail.then((_) async {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      try {
        final removed = await prefs.remove(key);
        if (!removed && prefs.containsKey(key)) {
          throw StateError('首页背景配置清除失败');
        }
        if (previousPath != null) await _backgroundStorage.delete(previousPath);
      } catch (error, stackTrace) {
        if (previousPath != null) {
          try {
            await prefs.setString(key, previousPath);
          } catch (_) {}
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
      if (ref.mounted) state = _stateWithPath(state, variant, null);
    });
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> _setDouble({
    required double value,
    required double fallback,
    required double max,
    required String key,
    required HomeBackgroundState Function(HomeBackgroundState, double) update,
  }) {
    final normalized = !value.isFinite
        ? fallback
        : value.clamp(0.0, max).toDouble();
    final previousState = state;
    final nextState = update(state, normalized);
    _hasExplicitState = true;
    state = nextState;
    final operation = _writeTail.then((_) async {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      if (!await prefs.setDouble(key, normalized)) {
        throw StateError('首页背景设置保存失败');
      }
    });
    _writeTail = operation.catchError((_) {});
    return operation.catchError((error, stackTrace) {
      if (ref.mounted && state == nextState) state = previousState;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }

  Future<void> setImageOpacity(double value) => _setDouble(
    value: value,
    fallback: homeBackgroundDefaultOpacity,
    max: 1.0,
    key: homeBackgroundOpacityPreferenceKey,
    update: (state, value) => state.copyWith(imageOpacity: value),
  );

  Future<void> setCardBlurSigma(double value) => _setDouble(
    value: value,
    fallback: homeBackgroundDefaultBlurSigma,
    max: homeBackgroundMaxBlurSigma,
    key: homeBackgroundBlurPreferenceKey,
    update: (state, value) => state.copyWith(cardBlurSigma: value),
  );

  Future<void> setDarkenStrength(double value) => _setDouble(
    value: value,
    fallback: homeBackgroundDefaultDarkenStrength,
    max: 1.0,
    key: homeBackgroundDarkenStrengthPreferenceKey,
    update: (state, value) => state.copyWith(darkenStrength: value),
  );

  Future<void> setDarkenEnabled(bool value) {
    final previousState = state;
    final nextState = state.copyWith(darkenEnabled: value);
    _hasExplicitState = true;
    state = nextState;
    final operation = _writeTail.then((_) async {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      if (!await prefs.setBool(
        homeBackgroundDarkenEnabledPreferenceKey,
        value,
      )) {
        throw StateError('首页背景设置保存失败');
      }
    });
    _writeTail = operation.catchError((_) {});
    return operation.catchError((error, stackTrace) {
      if (ref.mounted && state == nextState) state = previousState;
      Error.throwWithStackTrace(error, stackTrace);
    });
  }
}
