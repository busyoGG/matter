import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matter/providers/home_background_provider.dart';
import 'package:matter/providers/home_background_storage.dart';

class _FakeStorage implements HomeBackgroundStorage {
  final Map<String, Uint8List> files = {};
  bool failDelete = false;
  int _nextPath = 0;

  @override
  Future<String> save(Uint8List bytes, {required String extension}) async {
    final path = 'fake_${_nextPath++}.$extension';
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
) => ProviderContainer(
  overrides: [
    homeBackgroundProvider.overrideWith(
      () => HomeBackgroundNotifier(preferences: preferences, storage: storage),
    ),
  ],
);

void main() {
  test('persists and clears the shared home background', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = _FakeStorage();
    final container = _container(preferences, storage);
    addTearDown(container.dispose);

    final notifier = container.read(homeBackgroundProvider.notifier);
    await notifier.load();
    await notifier.setBackground(Uint8List.fromList([1]));

    expect(preferences.getString(homeBackgroundPreferenceKey), 'fake_0.jpg');
    expect(container.read(homeBackgroundProvider).path, 'fake_0.jpg');
    expect(storage.files, contains('fake_0.jpg'));

    await notifier.clearBackground();
    expect(preferences.getString(homeBackgroundPreferenceKey), isNull);
    expect(container.read(homeBackgroundProvider).path, isNull);
    expect(storage.files, isNot(contains('fake_0.jpg')));
  });

  test('migrates the first non-empty legacy background path', () async {
    SharedPreferences.setMockInitialValues({
      'home_background_path_chat': '',
      'home_background_path_spaces': 'legacy.jpg',
      'home_background_path_contacts': 'later.jpg',
    });
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences, _FakeStorage());
    addTearDown(container.dispose);

    await container.read(homeBackgroundProvider.notifier).load();

    expect(preferences.getString(homeBackgroundPreferenceKey), 'legacy.jpg');
    expect(container.read(homeBackgroundProvider).path, 'legacy.jpg');
    expect(preferences.containsKey('home_background_path_spaces'), isFalse);
    expect(preferences.containsKey('home_background_path_contacts'), isFalse);
  });

  test('keeps the shared background when its file cannot be deleted', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final storage = _FakeStorage();
    final container = _container(preferences, storage);
    addTearDown(container.dispose);
    final notifier = container.read(homeBackgroundProvider.notifier);

    await notifier.load();
    await notifier.setBackground(Uint8List.fromList([1]));
    storage.failDelete = true;

    await expectLater(notifier.clearBackground(), throwsA(isA<StateError>()));
    expect(container.read(homeBackgroundProvider).path, 'fake_0.jpg');
    expect(preferences.getString(homeBackgroundPreferenceKey), 'fake_0.jpg');
    expect(storage.files, contains('fake_0.jpg'));
  });

  test(
    'keeps light and dark backgrounds independent and preserves settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final storage = _FakeStorage();
      final container = _container(preferences, storage);
      addTearDown(container.dispose);
      final notifier = container.read(homeBackgroundProvider.notifier);

      await notifier.load();
      await notifier.setBackground(
        Uint8List.fromList([1]),
        variant: HomeBackgroundVariant.light,
      );
      await notifier.setBackground(
        Uint8List.fromList([2]),
        variant: HomeBackgroundVariant.dark,
      );
      await notifier.setImageOpacity(0.4);
      await notifier.setCardBlurSigma(29);
      await notifier.setDarkenEnabled(true);
      await notifier.setDarkenStrength(0.7);

      final state = container.read(homeBackgroundProvider);
      expect(state.path, 'fake_0.jpg');
      expect(state.darkPath, 'fake_1.jpg');
      expect(state.pathFor(dark: true), 'fake_1.jpg');
      expect(state.imageOpacity, 0.4);
      expect(state.cardBlurSigma, 29);
      expect(state.darkenEnabled, isTrue);
      expect(state.darkenStrength, 0.7);
      expect(
        preferences.getString(homeBackgroundDarkPreferenceKey),
        'fake_1.jpg',
      );

      await notifier.clearBackground(variant: HomeBackgroundVariant.light);
      expect(container.read(homeBackgroundProvider).path, isNull);
      expect(container.read(homeBackgroundProvider).darkPath, 'fake_1.jpg');
      expect(storage.files, contains('fake_1.jpg'));
    },
  );

  test('clamps invalid background settings and uses safe defaults', () async {
    SharedPreferences.setMockInitialValues({
      homeBackgroundOpacityPreferenceKey: 'invalid',
      homeBackgroundBlurPreferenceKey: 99,
      homeBackgroundDarkenEnabledPreferenceKey: 'invalid',
      homeBackgroundDarkenStrengthPreferenceKey: -1,
    });
    final preferences = await SharedPreferences.getInstance();
    final container = _container(preferences, _FakeStorage());
    addTearDown(container.dispose);

    final notifier = container.read(homeBackgroundProvider.notifier);
    await notifier.load();
    var state = container.read(homeBackgroundProvider);
    expect(state.imageOpacity, homeBackgroundDefaultOpacity);
    expect(state.cardBlurSigma, homeBackgroundMaxBlurSigma);
    expect(state.darkenEnabled, isFalse);
    expect(state.darkenStrength, 0.0);

    await notifier.setImageOpacity(2);
    await notifier.setCardBlurSigma(double.nan);
    await notifier.setDarkenStrength(-2);
    state = container.read(homeBackgroundProvider);
    expect(state.imageOpacity, 1.0);
    expect(state.cardBlurSigma, homeBackgroundDefaultBlurSigma);
    expect(state.darkenStrength, 0.0);
  });
}
