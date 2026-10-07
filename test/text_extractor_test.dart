import 'dart:convert';

import 'package:ai_hujjat/services/text_extractor.dart';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

List<int> _docx(String documentXml) {
  final data = utf8.encode(documentXml);
  final archive = Archive()..addFile(ArchiveFile('word/document.xml', data.length, data));
  return ZipEncoder().encode(archive);
}

void main() {
  test('docx paragraphs, runs, tabs and cyrillic text are extracted', () {
    const xml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>
<w:p><w:r><w:t>Hello </w:t></w:r><w:r><w:t>world</w:t></w:r></w:p>
<w:p><w:r><w:t>Шартнома</w:t></w:r><w:r><w:tab/></w:r><w:r><w:t>№5</w:t></w:r></w:p>
<w:p></w:p>
</w:body></w:document>''';
    expect(docxText(_docx(xml)), 'Hello world\n\nШартнома\t№5');
  });

  test('a zip without word/document.xml is rejected', () {
    final archive = Archive()..addFile(ArchiveFile('other.txt', 1, [65]));
    expect(() => docxText(ZipEncoder().encode(archive)), throwsA(isA<ExtractionException>()));
  });
}
