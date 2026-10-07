import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/models.dart';
import 'llm_catalog.dart';
import 'settings_service.dart';

/// A source the AI relied on: the index into the excerpts it was given and
/// the passages it quoted from it (may be empty if it only cited the number).
class CitedSource {
  CitedSource(this.index, this.quotes);
  final int index; // 0-based, into the hits list sent to the model
  final List<String> quotes;
}

class AiAnswer {
  AiAnswer({
    required this.text,
    required this.sources,
    required this.inputTokens,
    required this.outputTokens,
    this.costUsd,
  });
  final String text;
  final List<CitedSource> sources;
  final int inputTokens;
  final int outputTokens;

  /// Estimated price of this request; null when the model is not in the catalog.
  final double? costUsd;
}

class LlmException implements Exception {
  LlmException(this.message);
  final String message;
  @override
  String toString() => message;
}

const _systemPrompt = '''
You answer questions using ONLY the numbered document excerpts provided by the user.
Reply in the same language as the question.

Respond with one JSON object and nothing else:
{"answer": string, "sources": [{"id": number, "quote": string}]}

- "answer": the answer text. Cite the excerpts you used inline like [1], [2].
- "sources": one entry per passage you relied on. "id" is the excerpt number. "quote" is the shortest passage (one to three sentences) that supports the answer, copied EXACTLY, character for character, from that excerpt. Never paraphrase inside "quote".
- If the excerpts do not contain the answer, say so in "answer" and use "sources": []. Do not guess.''';

String buildUserPrompt(String question, List<SearchHit> hits) {
  final b = StringBuffer('Excerpts:\n\n');
  for (var i = 0; i < hits.length; i++) {
    b.writeln('[${i + 1}] (${hits[i].documentTitle})');
    b.writeln(hits[i].text);
    b.writeln();
  }
  b.write('Question: $question');
  return b.toString();
}

/// Reads the model's reply. Expects the JSON shape from [_systemPrompt] but
/// tolerates code fences, surrounding prose, or plain text (then the answer
/// is the raw text and sources are taken from inline [n] citations).
({String answer, List<CitedSource> sources}) parseStructuredAnswer(String raw, int hitCount) {
  final text = raw.trim();
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start >= 0 && end > start) {
    try {
      final json = jsonDecode(text.substring(start, end + 1));
      if (json is Map && json['answer'] is String) {
        final answer = (json['answer'] as String).trim();
        final quotes = <int, List<String>>{};
        for (final s in (json['sources'] is List ? json['sources'] as List : const [])) {
          if (s is! Map) continue;
          final id = s['id'] is num ? (s['id'] as num).toInt() : int.tryParse('${s['id']}');
          if (id == null || id < 1 || id > hitCount) continue;
          final list = quotes.putIfAbsent(id - 1, () => []);
          final q = s['quote'];
          if (q is String && q.trim().isNotEmpty) list.add(q.trim());
        }
        // Sources the answer cites inline but the list forgot.
        for (final i in _inlineCitations(answer, hitCount)) {
          quotes.putIfAbsent(i, () => []);
        }
        final ordered = quotes.keys.toList()..sort();
        return (answer: answer, sources: [for (final i in ordered) CitedSource(i, quotes[i]!)]);
      }
    } catch (_) {
      // fall through to plain text
    }
  }
  return (
    answer: text,
    sources: [for (final i in _inlineCitations(text, hitCount)) CitedSource(i, [])],
  );
}

List<int> _inlineCitations(String text, int hitCount) {
  final seen = <int>{};
  for (final m in RegExp(r'\[(\d{1,2})\]').allMatches(text)) {
    final n = int.parse(m.group(1)!);
    if (n >= 1 && n <= hitCount) seen.add(n - 1);
  }
  return seen.toList()..sort();
}

class _Raw {
  _Raw(this.text, this.inputTokens, this.outputTokens);
  final String text;
  final int inputTokens;
  final int outputTokens;
}

class LlmService {
  LlmService(this._settings, {http.Client? client}) : _client = client ?? http.Client();

  final SettingsService _settings;
  final http.Client _client;

  Future<AiAnswer> answer(String question, List<SearchHit> hits) async {
    final prompt = buildUserPrompt(question, hits);
    final provider = _settings.provider;
    final model = _settings.model;
    final raw = await switch (provider) {
      LlmProvider.anthropic => _anthropic(prompt),
      LlmProvider.openAi => _openAi(prompt),
    };
    final parsed = parseStructuredAnswer(raw.text, hits.length);
    return AiAnswer(
      text: parsed.answer,
      sources: parsed.sources,
      inputTokens: raw.inputTokens,
      outputTokens: raw.outputTokens,
      costUsd: findModel(provider, model)?.cost(raw.inputTokens, raw.outputTokens),
    );
  }

  Future<_Raw> _anthropic(String prompt) async {
    final model = _settings.model;
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': 2048,
      'system': _systemPrompt,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      // Haiku 4.5 rejects `effort`; newer models use it to keep answers cheap.
      if (!model.contains('haiku')) 'output_config': {'effort': 'low'},
    };
    final res = await _client
        .post(
          Uri.parse('https://api.anthropic.com/v1/messages'),
          headers: {
            'x-api-key': _settings.token,
            'anthropic-version': '2023-06-01',
            'content-type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(minutes: 2));
    final json = _decode(res);
    final text = (json['content'] as List)
        .where((b) => b['type'] == 'text')
        .map((b) => b['text'] as String)
        .join('\n')
        .trim();
    final usage = (json['usage'] ?? {}) as Map;
    return _Raw(text, (usage['input_tokens'] ?? 0) as int, (usage['output_tokens'] ?? 0) as int);
  }

  Future<_Raw> _openAi(String prompt) async {
    final base = _settings.baseUrl.replaceAll(RegExp(r'/+$'), '');
    // JSON mode is an OpenAI feature; other compatible servers may reject it.
    final isOpenAi = Uri.tryParse(base)?.host == 'api.openai.com';
    final res = await _client
        .post(
          Uri.parse('$base/chat/completions'),
          headers: {
            'authorization': 'Bearer ${_settings.token}',
            'content-type': 'application/json',
          },
          body: jsonEncode({
            'model': _settings.model,
            'messages': [
              {'role': 'system', 'content': _systemPrompt},
              {'role': 'user', 'content': prompt},
            ],
            if (isOpenAi) 'response_format': {'type': 'json_object'},
          }),
        )
        .timeout(const Duration(minutes: 2));
    final json = _decode(res);
    final text = (json['choices'][0]['message']['content'] as String? ?? '').trim();
    final usage = (json['usage'] ?? {}) as Map;
    return _Raw(text, (usage['prompt_tokens'] ?? 0) as int, (usage['completion_tokens'] ?? 0) as int);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = utf8.decode(res.bodyBytes);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      var msg = body;
      try {
        final err = (jsonDecode(body) as Map)['error'];
        if (err is Map && err['message'] != null) msg = err['message'].toString();
      } catch (_) {}
      throw LlmException('HTTP ${res.statusCode}: $msg');
    }
    return jsonDecode(body) as Map<String, dynamic>;
  }
}
