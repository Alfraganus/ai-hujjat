class Category {
  Category({required this.id, required this.name, required this.docCount});
  final int id;
  final String name;
  final int docCount;
}

class Document {
  Document({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.content,
    required this.updatedAt,
  });
  final int id;
  final int categoryId;
  final String title;
  final String content;
  final DateTime updatedAt;
}

class SearchHit {
  SearchHit({
    required this.chunkId,
    required this.documentId,
    required this.documentTitle,
    required this.text,
  });
  final int chunkId;
  final int documentId;
  final String documentTitle;
  final String text;
}
