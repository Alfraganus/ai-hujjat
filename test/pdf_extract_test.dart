import 'dart:io';

import 'package:ai_hujjat/services/text_extractor.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a minimal one-page PDF containing [text] (Latin only).
String _minimalPdf(String text) {
  final objs = <String>[
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 300 144] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
    '', // content stream, filled below
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];
  final stream = 'BT /F1 18 Tf 20 80 Td ($text) Tj ET';
  objs[3] = '<< /Length ${stream.length} >>\nstream\n$stream\nendstream';
  final b = StringBuffer('%PDF-1.4\n');
  final offsets = <int>[];
  for (var i = 0; i < objs.length; i++) {
    offsets.add(b.length);
    b.write('${i + 1} 0 obj\n${objs[i]}\nendobj\n');
  }
  final xref = b.length;
  b.write('xref\n0 ${objs.length + 1}\n0000000000 65535 f \n');
  for (final o in offsets) {
    b.write('${o.toString().padLeft(10, '0')} 00000 n \n');
  }
  b.write('trailer\n<< /Size ${objs.length + 1} /Root 1 0 R >>\nstartxref\n$xref\n%%EOF');
  return b.toString();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('extracts text from a PDF', () async {
    final dir = await Directory.systemTemp.createTemp('pdf_test');
    // pdfrx stores the downloaded pdfium binary under the temp directory.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => dir.path,
    );
    final file = File('${dir.path}/sample.pdf')..writeAsStringSync(_minimalPdf('Hello PDF world'));
    final text = await extractText(file.path);
    expect(text, contains('Hello PDF world'));
    await dir.delete(recursive: true);
  });
}
