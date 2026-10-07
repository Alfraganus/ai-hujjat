import 'package:ai_hujjat/data/chunker.dart';
import 'package:ai_hujjat/data/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late int law;
  late int cooking;

  setUp(() {
    db = AppDatabase.inMemory();
    law = db.createCategory('Law');
    cooking = db.createCategory('Cooking');
    db.saveDocument(categoryId: law, title: 'Contract', content: 'The tenant must pay rent on the first day of each month.');
    db.saveDocument(categoryId: cooking, title: 'Plov', content: 'Fry the onion and carrot, then add rice and rent a big pot.');
  });

  tearDown(() => db.close());

  test('search is scoped to the selected category', () {
    final inLaw = db.search('rent', categoryId: law);
    expect(inLaw.map((h) => h.documentTitle), ['Contract']);
    final inCooking = db.search('rent', categoryId: cooking);
    expect(inCooking.map((h) => h.documentTitle), ['Plov']);
    expect(db.search('rent').length, 2);
  });

  test('prefix and cyrillic/apostrophe-safe queries do not throw', () {
    expect(db.search('ten', categoryId: law), isNotEmpty);
    expect(db.search('"; DROP TABLE x; --', categoryId: law), isEmpty);
    db.saveDocument(categoryId: law, title: 'Шартнома', content: 'Ижарачи ойлик тўловни тўлаши шарт');
    expect(db.search('ойлик', categoryId: law).single.documentTitle, 'Шартнома');
  });

  test('editing moves chunks to the new category and reindexes', () {
    final doc = db.documents(categoryId: law).single;
    db.saveDocument(id: doc.id, categoryId: cooking, title: 'Contract', content: 'Completely different text about soup.');
    expect(db.search('tenant', categoryId: law), isEmpty);
    expect(db.search('soup', categoryId: cooking).length, 1);
  });

  test('deleting a category removes its documents from search', () {
    db.deleteCategory(law);
    expect(db.search('tenant'), isEmpty);
    expect(db.categories().map((c) => c.name), ['Cooking']);
  });

  test('chunker splits long text with overlap', () {
    final text = List.generate(40, (i) => 'Paragraph $i ${'word ' * 40}').join('\n\n');
    final chunks = chunkText(text);
    expect(chunks.length, greaterThan(1));
    expect(chunks.every((c) => c.length <= 1100), isTrue);
  });
}
