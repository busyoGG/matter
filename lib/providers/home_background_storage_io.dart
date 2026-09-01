import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

abstract class HomeBackgroundStorage {
  Future<String> save(Uint8List bytes, {required String extension});

  Future<void> delete(String path);
}

class IoHomeBackgroundStorage implements HomeBackgroundStorage {
  @override
  Future<String> save(Uint8List bytes, {required String extension}) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final directory = Directory(
      '${supportDirectory.path}${Platform.pathSeparator}home_backgrounds',
    );
    await directory.create(recursive: true);
    final normalizedExtension = extension.toLowerCase().replaceFirst('.', '');
    final fileName =
        'background_${DateTime.now().microsecondsSinceEpoch}.$normalizedExtension';
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

HomeBackgroundStorage createHomeBackgroundStorage() =>
    IoHomeBackgroundStorage();
