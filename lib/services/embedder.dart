import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

/// Turns text into a unit-length vector. [isQuery] selects the E5 prefix.
abstract class Embedder {
  /// Identifies the model; stored with vectors so a model change re-indexes.
  String get modelId;
  int get dimensions;
  Future<Float32List> embed(String text, {required bool isQuery});
}

class EmbedderUnavailable implements Exception {
  EmbedderUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

/// multilingual-e5-small (int8 ONNX) running locally via ONNX Runtime.
class OnnxE5Embedder implements Embedder {
  OnnxE5Embedder({String? modelDir}) : _modelDir = modelDir ?? defaultModelDir();

  final String _modelDir;
  OrtSession? _session;
  SentencePieceTokenizer? _tokenizer;
  Future<void>? _loading;

  static const maxTokens = 512;

  @override
  String get modelId => 'multilingual-e5-small-int8';
  @override
  int get dimensions => 384;

  /// Models are bundled as Flutter assets, which live next to the executable.
  static String defaultModelDir() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir${Platform.pathSeparator}data${Platform.pathSeparator}flutter_assets'
        '${Platform.pathSeparator}assets${Platform.pathSeparator}models'
        '${Platform.pathSeparator}multilingual-e5-small';
  }

  Future<void> _load() async {
    final model = File('$_modelDir${Platform.pathSeparator}model_quantized.onnx');
    final tok = File('$_modelDir${Platform.pathSeparator}tokenizer.json');
    if (!model.existsSync() || !tok.existsSync()) {
      throw EmbedderUnavailable('Embedding model files not found in $_modelDir');
    }
    _tokenizer = await TokenizerJsonLoader.fromJsonFile(tok.path);
    _tokenizer!.enableTruncation(maxLength: maxTokens);
    _session = await OnnxRuntime().createSession(model.path);
  }

  @override
  Future<Float32List> embed(String text, {required bool isQuery}) async {
    await (_loading ??= _load().catchError((Object e) {
      _loading = null; // allow a retry, e.g. after the files are added
      throw e;
    }));
    final enc = _tokenizer!.encode('${isQuery ? 'query' : 'passage'}: $text');
    final n = enc.ids.length;

    final inputs = {
      'input_ids': await OrtValue.fromList(Int64List.fromList(enc.ids), [1, n]),
      'attention_mask': await OrtValue.fromList(Int64List.fromList(enc.attentionMask), [1, n]),
      'token_type_ids': await OrtValue.fromList(Int64List(n), [1, n]),
    };
    final outputs = await _session!.run(inputs);
    try {
      final hidden = await outputs['last_hidden_state']!.asFlattenedList();
      return _meanPoolNormalize(hidden, enc.attentionMask, dimensions);
    } finally {
      for (final v in inputs.values) {
        await v.dispose();
      }
      for (final v in outputs.values) {
        await v.dispose();
      }
    }
  }
}

/// Mean-pools token vectors (weighted by the attention mask) and L2-normalizes.
Float32List _meanPoolNormalize(List<dynamic> hidden, List<int> mask, int dim) {
  final out = Float32List(dim);
  var count = 0;
  for (var t = 0; t < mask.length; t++) {
    if (mask[t] == 0) continue;
    count++;
    final base = t * dim;
    for (var d = 0; d < dim; d++) {
      out[d] += (hidden[base + d] as num).toDouble();
    }
  }
  if (count == 0) return out;
  var norm = 0.0;
  for (var d = 0; d < dim; d++) {
    out[d] /= count;
    norm += out[d] * out[d];
  }
  norm = sqrt(norm);
  if (norm > 0) {
    for (var d = 0; d < dim; d++) {
      out[d] /= norm;
    }
  }
  return out;
}

/// Deterministic bag-of-words embedder for tests (no model files needed).
class FakeEmbedder implements Embedder {
  @override
  String get modelId => 'fake';
  @override
  int get dimensions => 64;

  @override
  Future<Float32List> embed(String text, {required bool isQuery}) async {
    final v = Float32List(dimensions);
    for (final m in RegExp(r'[\p{L}\p{N}]+', unicode: true).allMatches(text.toLowerCase())) {
      v[m.group(0)!.hashCode.abs() % dimensions] += 1;
    }
    var norm = 0.0;
    for (final x in v) {
      norm += x * x;
    }
    norm = sqrt(norm);
    if (norm > 0) {
      for (var i = 0; i < v.length; i++) {
        v[i] /= norm;
      }
    }
    return v;
  }
}
