import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

import '../services/app_log.dart';

const _dbName = 'ai_hujjat.db';

/// Early builds stored data in `<AppData>\uz.aihujjat\ai_hujjat`; after the
/// Windows product name became "AI Hujjat" the app folder is
/// `<AppData>\uz.aihujjat\AI Hujjat`. If the old folder holds user data and the
/// new one has none yet (no database, or only an empty one from a first run),
/// copy the database and settings across. The old folder is left untouched.
///
/// Returns true when something was copied.
Future<bool> migrateLegacyDataDir(Directory current, {String legacyName = 'ai_hujjat'}) async {
  final legacy = Directory(p.join(current.parent.path, legacyName));
  try {
    if (p.canonicalize(legacy.path) == p.canonicalize(current.path)) return false;
    if (!legacy.existsSync()) return false;
    if (_userDataRows(p.join(legacy.path, _dbName)) == 0) return false;
    if (_userDataRows(p.join(current.path, _dbName)) > 0) return false;

    await current.create(recursive: true);
    // Stale sidecar files of an empty database must not be mixed with the copy.
    for (final suffix in ['-wal', '-shm']) {
      final stale = File(p.join(current.path, '$_dbName$suffix'));
      if (stale.existsSync()) stale.deleteSync();
    }
    var copied = 0;
    for (final name in [_dbName, '$_dbName-wal', 'shared_preferences.json']) {
      final src = File(p.join(legacy.path, name));
      if (!src.existsSync() || src.lengthSync() == 0) continue;
      await src.copy(p.join(current.path, name));
      copied++;
    }
    AppLog.write('migrated $copied file(s) from ${legacy.path}');
    return copied > 0;
  } catch (e) {
    AppLog.write('legacy migration failed: $e');
    return false;
  }
}

/// Categories + documents in the database at [path]; 0 if missing or unreadable.
int _userDataRows(String path) {
  if (!File(path).existsSync()) return 0;
  Database? db;
  try {
    db = sqlite3.open(path, mode: OpenMode.readOnly);
    final n = db.select('SELECT (SELECT COUNT(*) FROM categories) + (SELECT COUNT(*) FROM documents) AS n').first['n'];
    return n as int;
  } catch (_) {
    return 0;
  } finally {
    db?.close();
  }
}
