import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:xml/xml.dart';

const supportedImportExtensions = ['txt', 'md', 'pdf', 'docx'];

class ExtractionException implements Exception {
  ExtractionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Reads plain text out of a .txt/.md/.pdf/.docx file.
/// Returns an empty string when the file has no extractable text
/// (e.g. a scanned PDF, which would need OCR).
Future<String> extractText(String path) async {
  final ext = path.split('.').last.toLowerCase();
  switch (ext) {
    case 'txt':
    case 'md':
      return File(path).readAsString();
    case 'pdf':
      return _pdfText(path);
    case 'docx':
      return docxText(await File(path).readAsBytes());
    default:
      throw ExtractionException('Unsupported file type: .$ext');
  }
}

Future<String> _pdfText(String path) async {
  await pdfrxFlutterInitialize();
  final doc = await PdfDocument.openFile(path);
  try {
    final pages = <String>[];
    for (final page in doc.pages) {
      final text = await page.loadText();
      final t = text?.fullText.trim() ?? '';
      if (t.isNotEmpty) pages.add(t);
    }
    return pages.join('\n\n');
  } finally {
    await doc.dispose();
  }
}

/// Extracts paragraph text from the raw bytes of a .docx file.
String docxText(List<int> bytes) {
  final archive = ZipDecoder().decodeBytes(bytes);
  final file = archive.findFile('word/document.xml');
  if (file == null) throw ExtractionException('Not a valid .docx file');
  final xml = XmlDocument.parse(utf8.decode(file.readBytes()!));

  final paragraphs = <String>[];
  for (final p in xml.findAllElements('w:p')) {
    final b = StringBuffer();
    for (final node in p.descendantElements) {
      switch (node.name.qualified) {
        case 'w:t':
          b.write(node.innerText);
        case 'w:tab':
          b.write('\t');
        case 'w:br':
          b.write('\n');
      }
    }
    final line = b.toString().trim();
    if (line.isNotEmpty) paragraphs.add(line);
  }
  return paragraphs.join('\n\n');
}
