import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Tiny append-only log in the app data folder (app.log), used to diagnose
/// problems on machines where nobody is watching a console. Never throws.
class AppLog {
  AppLog._();

  static File? _file;
  static const _maxBytes = 512 * 1024;

  static Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      await dir.create(recursive: true);
      final file = File(p.join(dir.path, 'app.log'));
      // Keep the log small: start over once it grows past the limit.
      if (file.existsSync() && file.lengthSync() > _maxBytes) file.deleteSync();
      _file = file;
    } catch (_) {
      _file = null;
    }
  }

  static String? get path => _file?.path;

  static void write(String message) {
    final file = _file;
    if (file == null) return;
    try {
      file.writeAsStringSync('${DateTime.now().toIso8601String()}  $message\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Logging must never break the app.
    }
  }
}
