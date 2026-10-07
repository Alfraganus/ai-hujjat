import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import 'chunker.dart';
import 'models.dart';

class AppDatabase {
  AppDatabase._(this._db);
  final Database _db;

  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    await Directory(dir.path).create(recursive: true);
    final db = sqlite3.open(p.join(dir.path, 'ai_hujjat.db'));
    final instance = AppDatabase._(db);
    instance._migrate();
    return instance;
  }

  static AppDatabase inMemory() {
    final instance = AppDatabase._(sqlite3.openInMemory());
    instance._migrate();
    return instance;
  }

  void _migrate() {
    _db.execute('PRAGMA foreign_keys = ON');
    _db.execute('PRAGMA journal_mode = WAL');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS documents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS chunks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
        category_id INTEGER NOT NULL,
        idx INTEGER NOT NULL,
        text TEXT NOT NULL
      );
      CREATE TABLE IF NOT EXISTS chunk_vec (
        chunk_id INTEGER PRIMARY KEY REFERENCES chunks(id) ON DELETE CASCADE,
        model TEXT NOT NULL,
        embedding BLOB NOT NULL
      );
      CREATE INDEX IF NOT EXISTS idx_chunks_category ON chunks(category_id);
      CREATE INDEX IF NOT EXISTS idx_documents_category ON documents(category_id);
      CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts
        USING fts5(text, tokenize = 'unicode61 remove_diacritics 2');
      CREATE TRIGGER IF NOT EXISTS chunks_ai AFTER INSERT ON chunks BEGIN
        INSERT INTO chunks_fts(rowid, text) VALUES (new.id, new.text);
      END;
      CREATE TRIGGER IF NOT EXISTS chunks_ad AFTER DELETE ON chunks BEGIN
        DELETE FROM chunks_fts WHERE rowid = old.id;
      END;
    ''');
  }

  int _now() => DateTime.now().millisecondsSinceEpoch;

  // ---- Categories -------------------------------------------------------

  List<Category> categories() {
    final rows = _db.select('''
      SELECT c.id, c.name, COUNT(d.id) AS n
      FROM categories c LEFT JOIN documents d ON d.category_id = c.id
      GROUP BY c.id ORDER BY c.name COLLATE NOCASE
    ''');
    return [
      for (final r in rows)
        Category(id: r['id'] as int, name: r['name'] as String, docCount: r['n'] as int),
    ];
  }

  int createCategory(String name) {
    _db.execute('INSERT INTO categories(name, created_at) VALUES (?, ?)', [name.trim(), _now()]);
    return _db.lastInsertRowId;
  }

  void renameCategory(int id, String name) =>
      _db.execute('UPDATE categories SET name = ? WHERE id = ?', [name.trim(), id]);

  /// Deleting the category cascades to documents, and documents to chunks
  /// (whose FTS rows are removed by the chunks_ad trigger).
  void deleteCategory(int id) => _db.execute('DELETE FROM categories WHERE id = ?', [id]);

  // ---- Documents --------------------------------------------------------

  List<Document> documents({int? categoryId}) {
    final rows = categoryId == null
        ? _db.select('SELECT * FROM documents ORDER BY updated_at DESC')
        : _db.select('SELECT * FROM documents WHERE category_id = ? ORDER BY updated_at DESC', [categoryId]);
    return [
      for (final r in rows)
        Document(
          id: r['id'] as int,
          categoryId: r['category_id'] as int,
          title: r['title'] as String,
          content: r['content'] as String,
          updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int),
        ),
    ];
  }

  int saveDocument({int? id, required int categoryId, required String title, required String content}) {
    _db.execute('BEGIN');
    try {
      final now = _now();
      int docId;
      if (id == null) {
        _db.execute(
          'INSERT INTO documents(category_id, title, content, created_at, updated_at) VALUES (?,?,?,?,?)',
          [categoryId, title.trim(), content, now, now],
        );
        docId = _db.lastInsertRowId;
      } else {
        docId = id;
        _db.execute(
          'UPDATE documents SET category_id = ?, title = ?, content = ?, updated_at = ? WHERE id = ?',
          [categoryId, title.trim(), content, now, id],
        );
        _db.execute('DELETE FROM chunks WHERE document_id = ?', [id]);
      }
      final stmt = _db.prepare('INSERT INTO chunks(document_id, category_id, idx, text) VALUES (?,?,?,?)');
      final chunks = chunkText('${title.trim()}\n\n$content');
      for (var i = 0; i < chunks.length; i++) {
        stmt.execute([docId, categoryId, i, chunks[i]]);
      }
      stmt.close();
      _db.execute('COMMIT');
      return docId;
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void deleteDocument(int id) => _db.execute('DELETE FROM documents WHERE id = ?', [id]);

  // ---- Search -----------------------------------------------------------

  /// Full-text search restricted to [categoryId] (all categories when null).
  List<SearchHit> search(String query, {int? categoryId, int limit = 8}) {
    final terms = queryTerms(query);
    if (terms.isEmpty) return const [];
    // AND first for precision; fall back to OR for recall.
    for (final joiner in const [' AND ', ' OR ']) {
      final match = terms.map((t) => '"$t"*').join(joiner);
      final hits = _runSearch(match, categoryId, limit);
      if (hits.isNotEmpty) return hits;
      if (terms.length == 1) break;
    }
    return const [];
  }

  List<SearchHit> _runSearch(String match, int? categoryId, int limit) {
    final rows = _db.select('''
      SELECT c.id AS chunk_id, c.text AS text, d.id AS doc_id, d.title AS title
      FROM chunks_fts f
      JOIN chunks c ON c.id = f.rowid
      JOIN documents d ON d.id = c.document_id
      WHERE chunks_fts MATCH ? ${categoryId == null ? '' : 'AND c.category_id = ?'}
      ORDER BY bm25(chunks_fts)
      LIMIT ?
    ''', [match, ?categoryId, limit]);
    return [
      for (final r in rows)
        SearchHit(
          chunkId: r['chunk_id'] as int,
          documentId: r['doc_id'] as int,
          documentTitle: r['title'] as String,
          text: r['text'] as String,
        ),
    ];
  }

  // ---- Vectors ----------------------------------------------------------

  /// Number of chunks that have no embedding from [model] yet.
  int pendingEmbeddingCount(String model) => _db.select('''
      SELECT COUNT(*) AS n FROM chunks c
      LEFT JOIN chunk_vec v ON v.chunk_id = c.id AND v.model = ?
      WHERE v.chunk_id IS NULL
    ''', [model]).first['n'] as int;

  /// Chunks still waiting for an embedding from [model] (oldest first).
  List<({int id, String text})> chunksNeedingEmbedding(String model, {int limit = 32}) {
    final rows = _db.select('''
      SELECT c.id, c.text FROM chunks c
      LEFT JOIN chunk_vec v ON v.chunk_id = c.id AND v.model = ?
      WHERE v.chunk_id IS NULL
      ORDER BY c.id LIMIT ?
    ''', [model, limit]);
    return [for (final r in rows) (id: r['id'] as int, text: r['text'] as String)];
  }

  void saveEmbedding(int chunkId, String model, Float32List vector) {
    // The chunk may have been deleted/re-chunked while we were embedding it,
    // in which case the SELECT yields no row and nothing is stored.
    _db.execute(
      'INSERT OR REPLACE INTO chunk_vec(chunk_id, model, embedding) SELECT id, ?, ? FROM chunks WHERE id = ?',
      [model, vector.buffer.asUint8List(vector.offsetInBytes, vector.lengthInBytes), chunkId],
    );
  }

  /// Nearest chunks by cosine similarity (vectors are unit length, so a dot
  /// product), restricted to [categoryId] when given. Brute force: fine for
  /// tens of thousands of chunks, and avoids a native vector extension.
  List<SearchHit> vectorSearch(Float32List query, String model, {int? categoryId, int limit = 8}) {
    final rows = _db.select('''
      SELECT c.id AS chunk_id, c.text AS text, d.id AS doc_id, d.title AS title, v.embedding AS emb
      FROM chunk_vec v
      JOIN chunks c ON c.id = v.chunk_id
      JOIN documents d ON d.id = c.document_id
      WHERE v.model = ? ${categoryId == null ? '' : 'AND c.category_id = ?'}
    ''', [model, ?categoryId]);

    final scored = <(double, Row)>[];
    for (final r in rows) {
      final blob = r['emb'] as Uint8List;
      // Float32List views need 4-byte alignment; copy in the rare unaligned case.
      final vec = blob.offsetInBytes % 4 == 0
          ? Float32List.sublistView(blob)
          : Float32List.sublistView(Uint8List.fromList(blob));
      if (vec.length != query.length) continue;
      var dot = 0.0;
      for (var i = 0; i < vec.length; i++) {
        dot += vec[i] * query[i];
      }
      scored.add((dot, r));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    return [
      for (final (_, r) in scored.take(limit))
        SearchHit(
          chunkId: r['chunk_id'] as int,
          documentId: r['doc_id'] as int,
          documentTitle: r['title'] as String,
          text: r['text'] as String,
        ),
    ];
  }

  void close() => _db.close();
}

/// Splits user input into safe FTS5 terms (letters/digits only).
List<String> queryTerms(String query) {
  return RegExp(r'[\p{L}\p{N}]+', unicode: true)
      .allMatches(query)
      .map((m) => m.group(0)!)
      .toList();
}
