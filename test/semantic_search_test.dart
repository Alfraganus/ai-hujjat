import 'dart:typed_data';

import 'package:ai_hujjat/data/database.dart';
import 'package:ai_hujjat/data/models.dart';
import 'package:ai_hujjat/services/embedder.dart';
import 'package:ai_hujjat/services/search_service.dart';
import 'package:flutter_test/flutter_test.dart';

SearchHit _hit(int id) => SearchHit(chunkId: id, documentId: id, documentTitle: 'd$id', text: 't$id');

void main() {
  late AppDatabase db;
  late FakeEmbedder embedder;
  late IndexingService indexer;
  late SearchService search;
  late int a;
  late int b;

  setUp(() async {
    db = AppDatabase.inMemory();
    embedder = FakeEmbedder();
    indexer = IndexingService(db, embedder);
    search = SearchService(db, embedder);
    a = db.createCategory('A');
    b = db.createCategory('B');
    db.saveDocument(categoryId: a, title: 'Rent', content: 'tenant pays monthly rent for the apartment');
    db.saveDocument(categoryId: b, title: 'Soup', content: 'boil carrots and onions for soup');
    await indexer.run();
  });

  tearDown(() => db.close());

  test('indexer embeds every chunk and reports nothing pending', () {
    expect(indexer.pending, 0);
    expect(db.pendingEmbeddingCount(embedder.modelId), 0);
  });

  test('vector search is scoped to the category', () async {
    final q = await embedder.embed('monthly rent apartment', isQuery: true);
    expect(db.vectorSearch(q, embedder.modelId, categoryId: a).map((h) => h.documentTitle), ['Rent']);
    expect(db.vectorSearch(q, embedder.modelId, categoryId: b).map((h) => h.documentTitle), ['Soup']);
  });

  test('editing a document re-queues and re-embeds only its new chunks', () async {
    final doc = db.documents(categoryId: a).single;
    db.saveDocument(id: doc.id, categoryId: a, title: 'Rent', content: 'completely new text about bicycles');
    expect(db.pendingEmbeddingCount(embedder.modelId), 1);
    await indexer.run();
    expect(db.pendingEmbeddingCount(embedder.modelId), 0);
    final q = await embedder.embed('bicycles', isQuery: true);
    expect(db.vectorSearch(q, embedder.modelId, categoryId: a).first.documentTitle, 'Rent');
  });

  test('deleting a document removes its vectors', () async {
    final doc = db.documents(categoryId: a).single;
    db.deleteDocument(doc.id);
    final q = await embedder.embed('rent', isQuery: true);
    expect(db.vectorSearch(q, embedder.modelId, categoryId: a), isEmpty);
  });

  test('hybrid search finds results and respects the category', () async {
    final hits = await search.search('rent apartment', categoryId: a);
    expect(hits.first.documentTitle, 'Rent');
    expect(await search.search('rent apartment', categoryId: b), everyElement(predicate<SearchHit>((h) => h.documentTitle == 'Soup')));
  });

  test('falls back to keyword search when the embedder fails', () async {
    final broken = SearchService(db, _BrokenEmbedder());
    final hits = await broken.search('tenant', categoryId: a);
    expect(hits.single.documentTitle, 'Rent');
    expect(broken.semanticError, isNotNull);
  });

  test('reciprocal rank fusion boosts items present in both lists', () {
    final merged = reciprocalRankFusion([
      [_hit(1), _hit(2), _hit(3)],
      [_hit(3), _hit(4)],
    ]);
    expect(merged.first.chunkId, 3);
    expect(merged.map((h) => h.chunkId).toSet(), {1, 2, 3, 4});
  });
}

class _BrokenEmbedder extends FakeEmbedder {
  @override
  Future<Float32List> embed(String text, {required bool isQuery}) => throw EmbedderUnavailable('no model');
}
