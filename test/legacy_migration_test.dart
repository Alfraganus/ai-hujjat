import 'dart:io';

import 'package:ai_hujjat/data/legacy_migration.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Creates a database with the app's tables and [categories] category rows.
void _makeDb(String path, {int categories = 0}) {
  Directory(p.dirname(path)).createSync(recursive: true);
  final db = sqlite3.open(path);
  db.execute('CREATE TABLE categories (id INTEGER PRIMARY KEY, name TEXT); CREATE TABLE documents (id INTEGER PRIMARY KEY)');
  for (var i = 0; i < categories; i++) {
    db.execute('INSERT INTO categories(name) VALUES (?)', ['cat$i']);
  }
  db.close();
}

int _categories(String path) {
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  try {
    return db.select('SELECT COUNT(*) AS n FROM categories').first['n'] as int;
  } finally {
    db.close();
  }
}

void main() {
  late Directory root;
  late String legacyDb;
  late Directory current;
  late String currentDb;

  setUp(() {
    root = Directory.systemTemp.createTempSync('migrate_test');
    legacyDb = p.join(root.path, 'ai_hujjat', 'ai_hujjat.db');
    current = Directory(p.join(root.path, 'AI Hujjat'));
    currentDb = p.join(current.path, 'ai_hujjat.db');
  });

  tearDown(() => root.deleteSync(recursive: true));

  test('copies data and settings from the old folder when the new one is absent', () async {
    _makeDb(legacyDb, categories: 3);
    File(p.join(root.path, 'ai_hujjat', 'shared_preferences.json')).writeAsStringSync('{"a":1}');

    expect(await migrateLegacyDataDir(current), isTrue);
    expect(_categories(currentDb), 3);
    expect(File(p.join(current.path, 'shared_preferences.json')).readAsStringSync(), '{"a":1}');
    expect(File(legacyDb).existsSync(), isTrue, reason: 'old data is kept');
  });

  test('replaces an empty database created by a first run of the new build', () async {
    _makeDb(legacyDb, categories: 2);
    _makeDb(currentDb);

    expect(await migrateLegacyDataDir(current), isTrue);
    expect(_categories(currentDb), 2);
  });

  test('never overwrites a new database that already has data', () async {
    _makeDb(legacyDb, categories: 2);
    _makeDb(currentDb, categories: 1);

    expect(await migrateLegacyDataDir(current), isFalse);
    expect(_categories(currentDb), 1);
  });

  test('does nothing when the old folder has no data', () async {
    _makeDb(legacyDb);
    expect(await migrateLegacyDataDir(current), isFalse);
    expect(File(currentDb).existsSync(), isFalse);
  });

  test('does nothing when there is no old folder or the folders are the same', () async {
    expect(await migrateLegacyDataDir(current), isFalse);
    _makeDb(legacyDb, categories: 1);
    expect(await migrateLegacyDataDir(Directory(p.dirname(legacyDb))), isFalse);
  });
}
