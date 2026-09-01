import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_provider.dart';
import 'home_background_storage.dart';

typedef RoomBackgroundKey = RoomAccountKey;

class RoomBackgroundState {
  final String? path;

  const RoomBackgroundState({this.path});
}

String roomBackgroundPreferenceKey(RoomBackgroundKey key) =>
    'room_background_path_v1:${Uri.encodeComponent(key.userId)}:${Uri.encodeComponent(key.roomId)}';

final roomBackgroundProvider =
    NotifierProvider.family<
      RoomBackgroundNotifier,
      RoomBackgroundState,
      RoomAccountKey
    >(RoomBackgroundNotifier.new);

class RoomBackgroundNotifier extends Notifier<RoomBackgroundState> {
  RoomBackgroundNotifier(this.key, {this.preferences, this.storage});

  final RoomAccountKey key;
  final SharedPreferences? preferences;
  final HomeBackgroundStorage? storage;
  Future<void>? _loadFuture;
  Future<void> _writeTail = Future.value();
  bool _hasExplicitState = false;

  HomeBackgroundStorage get _backgroundStorage =>
      storage ?? createHomeBackgroundStorage();

  String get _preferenceKey => roomBackgroundPreferenceKey(key);

  @override
  RoomBackgroundState build() {
    unawaited(load());
    return const RoomBackgroundState();
  }

  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      if (_hasExplicitState) return;
      final path = prefs.getString(_preferenceKey);
      await Future<void>.value();
      if (ref.mounted && !_hasExplicitState) {
        state = RoomBackgroundState(
          path: path == null || path.isEmpty ? null : path,
        );
      }
    } catch (_) {
      // The room remains usable when preferences are unavailable.
    }
  }

  Future<void> setBackground(Uint8List bytes, {String extension = 'jpg'}) {
    final previousPath = state.path;
    _hasExplicitState = true;
    final operation = _writeTail.then((_) async {
      final nextPath = await _backgroundStorage.save(
        bytes,
        extension: extension,
      );
      try {
        final prefs = preferences ?? await SharedPreferences.getInstance();
        if (!await prefs.setString(_preferenceKey, nextPath)) {
          throw StateError('聊天背景路径保存失败');
        }
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
          // Keep the new valid background when an old file is orphaned.
        }
      }
      if (ref.mounted) state = RoomBackgroundState(path: nextPath);
    });
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<void> clearBackground() {
    final previousPath = state.path;
    _hasExplicitState = true;
    final operation = _writeTail.then((_) async {
      final prefs = preferences ?? await SharedPreferences.getInstance();
      try {
        final removed = await prefs.remove(_preferenceKey);
        if (!removed && prefs.containsKey(_preferenceKey)) {
          throw StateError('聊天背景配置清除失败');
        }
        if (previousPath != null) await _backgroundStorage.delete(previousPath);
      } catch (error, stackTrace) {
        if (previousPath != null) {
          try {
            await prefs.setString(_preferenceKey, previousPath);
          } catch (_) {}
        }
        Error.throwWithStackTrace(error, stackTrace);
      }
      if (ref.mounted) state = const RoomBackgroundState();
    });
    _writeTail = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
