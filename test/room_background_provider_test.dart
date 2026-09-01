import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matter/providers/home_background_storage.dart';
import 'package:matter/providers/room_background_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeStorage implements HomeBackgroundStorage {
  final Map<String, Uint8List> files = {};
  bool failDelete = false;
  int _nextPath = 0;

  @override
  Future<String> save(Uint8List bytes, {required String extension}) async {
    final path = 'room_${_nextPath++}.$extension';
    files[path] = bytes;
    return path;
  }

  @override
  Future<void> delete(String path) async {
    if (failDelete) throw StateError('delete failed');
    files.remove(path);
  }
}

ProviderContainer _container(
  SharedPreferences preferences,
  _FakeStorage storage,
  RoomBackgroundKey key,
) => ProviderContainer(
  overrides: [
    roomBackgroundProvider(key).overrideWith(
      () => RoomBackgroundNotifier(
        key,
        preferences: preferences,
        storage: storage,
      ),
    ),
  ],
);

void main() {
  test('isolates backgrounds by room and account', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = _FakeStorage();
    const roomA = (roomId: '!a:example.org', userId: '@alice:example.org');
    const roomB = (roomId: '!b:example.org', userId: '@alice:example.org');
    const otherAccount = (roomId: '!a:example.org', userId: '@bob:example.org');
    final containerA = _container(preferences, storage, roomA);
    final containerB = _container(preferences, storage, roomB);
    final otherContainer = _container(preferences, storage, otherAccount);
    addTearDown(() {
      containerA.dispose();
      containerB.dispose();
      otherContainer.dispose();
    });

    final notifierA = containerA.read(roomBackgroundProvider(roomA).notifier);
    await notifierA.load();
    await notifierA.setBackground(Uint8List.fromList([1]));

    expect(containerA.read(roomBackgroundProvider(roomA)).path, 'room_0.jpg');
    expect(containerB.read(roomBackgroundProvider(roomB)).path, isNull);
    expect(
      otherContainer.read(roomBackgroundProvider(otherAccount)).path,
      isNull,
    );
    expect(
      preferences.getString(roomBackgroundPreferenceKey(roomA)),
      'room_0.jpg',
    );
    expect(preferences.getString(roomBackgroundPreferenceKey(roomB)), isNull);
  });

  test('replaces and clears one room without affecting another', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = _FakeStorage();
    const roomA = (roomId: '!a:example.org', userId: '@alice:example.org');
    const roomB = (roomId: '!b:example.org', userId: '@alice:example.org');
    final containerA = _container(preferences, storage, roomA);
    final containerB = _container(preferences, storage, roomB);
    addTearDown(() {
      containerA.dispose();
      containerB.dispose();
    });

    final notifierA = containerA.read(roomBackgroundProvider(roomA).notifier);
    final notifierB = containerB.read(roomBackgroundProvider(roomB).notifier);
    await notifierA.load();
    await notifierB.load();
    await notifierA.setBackground(Uint8List.fromList([1]));
    await notifierB.setBackground(Uint8List.fromList([2]));
    await notifierA.setBackground(Uint8List.fromList([3]), extension: 'png');

    expect(storage.files, contains('room_1.jpg'));
    expect(storage.files, contains('room_2.png'));
    expect(storage.files, isNot(contains('room_0.jpg')));
    expect(containerB.read(roomBackgroundProvider(roomB)).path, 'room_1.jpg');

    await notifierA.clearBackground();
    expect(containerA.read(roomBackgroundProvider(roomA)).path, isNull);
    expect(storage.files, contains('room_1.jpg'));
    expect(preferences.getString(roomBackgroundPreferenceKey(roomA)), isNull);
  });

  test('restores the room path when deleting the file fails', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = _FakeStorage();
    const key = (roomId: '!room:example.org', userId: '@alice:example.org');
    final container = _container(preferences, storage, key);
    addTearDown(container.dispose);
    final notifier = container.read(roomBackgroundProvider(key).notifier);

    await notifier.load();
    await notifier.setBackground(Uint8List.fromList([1]));
    storage.failDelete = true;

    await expectLater(notifier.clearBackground(), throwsA(isA<StateError>()));
    expect(container.read(roomBackgroundProvider(key)).path, 'room_0.jpg');
    expect(
      preferences.getString(roomBackgroundPreferenceKey(key)),
      'room_0.jpg',
    );
    expect(storage.files, contains('room_0.jpg'));
  });
}
