import 'dart:typed_data';

abstract class HomeBackgroundStorage {
  Future<String> save(Uint8List bytes, {required String extension});

  Future<void> delete(String path);
}

class UnsupportedHomeBackgroundStorage implements HomeBackgroundStorage {
  @override
  Future<String> save(Uint8List bytes, {required String extension}) {
    throw UnsupportedError('本平台不支持本地首页背景');
  }

  @override
  Future<void> delete(String path) async {}
}

HomeBackgroundStorage createHomeBackgroundStorage() =>
    UnsupportedHomeBackgroundStorage();
