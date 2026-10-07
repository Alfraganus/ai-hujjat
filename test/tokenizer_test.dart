import 'dart:io';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

const _tokenizerPath = 'assets/models/multilingual-e5-small/tokenizer.json';

void main() {
  test('e5 tokenizer matches known XLM-R ids', () async {
    final tok = await TokenizerJsonLoader.fromJsonFile(_tokenizerPath);
    tok.enableTruncation(maxLength: 512);
    final enc = tok.encode('Hello world');
    // <s> ▁Hello ▁world </s>
    expect(enc.ids.toList(), [0, 35378, 8999, 2]);
    expect(enc.attentionMask.toList(), [1, 1, 1, 1]);

    final uz = tok.encode("query: o'zbek tilida qidiruv");
    expect(uz.ids.first, 0);
    expect(uz.ids.last, 2);
    expect(uz.ids.length, greaterThan(5));
  }, skip: File(_tokenizerPath).existsSync() ? false : 'run tool/download_model.ps1 first');
}
