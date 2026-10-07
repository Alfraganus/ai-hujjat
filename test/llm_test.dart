import 'dart:convert';

import 'package:ai_hujjat/data/models.dart';
import 'package:ai_hujjat/services/llm_catalog.dart';
import 'package:ai_hujjat/services/llm_service.dart';
import 'package:ai_hujjat/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _hits = [SearchHit(chunkId: 1, documentId: 1, documentTitle: 'Doc', text: 'Rent is due monthly.')];

Future<SettingsService> _settings([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SettingsService.load();
}

void main() {
  test('model lists are ordered cheapest first', () {
    for (final list in [anthropicModels, openAiModels]) {
      for (var i = 1; i < list.length; i++) {
        final prev = list[i - 1], cur = list[i];
        expect(cur.inputPerM >= prev.inputPerM, isTrue, reason: '${cur.id} input price after ${prev.id}');
        if (cur.inputPerM == prev.inputPerM) expect(cur.outputPerM >= prev.outputPerM, isTrue, reason: cur.id);
      }
    }
    expect(openAiModels.first.id, 'gpt-5-nano');
    expect(modelsFor(LlmProvider.openAi), same(openAiModels));
    expect(findModel(LlmProvider.openAi, defaultModelFor(LlmProvider.openAi)), isNotNull);
    expect(findModel(LlmProvider.anthropic, defaultModelFor(LlmProvider.anthropic)), isNotNull);
  });

  test('cost is computed from per-million prices', () {
    final m = findModel(LlmProvider.openAi, 'gpt-6-luna')!; // $0.10 / $0.50
    expect(m.cost(2800, 400), closeTo(0.00028 + 0.0002, 1e-9));
    expect(m.priceLabel, r'$0.10 / $0.50');
    expect(findModel(LlmProvider.anthropic, 'claude-haiku-4-5')!.priceLabel, r'$1 / $5');
  });

  test('model and token are kept separately per provider', () async {
    final s = await _settings();
    await s.saveAi(
      provider: LlmProvider.openAi,
      models: {LlmProvider.anthropic: 'claude-sonnet-5-5', LlmProvider.openAi: 'gpt-5-mini'},
      tokens: {LlmProvider.anthropic: 'sk-ant-1', LlmProvider.openAi: 'sk-openai-2'},
      baseUrl: defaultOpenAiBaseUrl,
      maxContext: 5,
    );
    expect(s.provider, LlmProvider.openAi);
    expect(s.model, 'gpt-5-mini');
    expect(s.token, 'sk-openai-2');
    expect(s.tokenFor(LlmProvider.anthropic), 'sk-ant-1');
    expect(s.modelFor(LlmProvider.anthropic), 'claude-sonnet-5-5');

    // Reloading from disk gives the same values (token round-trips through encryption).
    final reloaded = await SettingsService.load();
    expect(reloaded.tokenFor(LlmProvider.anthropic), 'sk-ant-1');
    expect(reloaded.token, 'sk-openai-2');
  });

  test('old single model/token settings migrate to the saved provider', () async {
    final s = await _settings({'provider': 'openai', 'model': 'gpt-5', 'base_url': 'http://localhost:1234/v1'});
    expect(s.provider, LlmProvider.openAi);
    expect(s.model, 'gpt-5');
    expect(s.modelFor(LlmProvider.anthropic), 'claude-haiku-4-5'); // default, untouched
    expect(s.baseUrl, 'http://localhost:1234/v1');
  });

  test('OpenAI request goes to base_url/chat/completions with the OpenAI token', () async {
    final s = await _settings();
    await s.saveAi(
      provider: LlmProvider.openAi,
      models: {LlmProvider.anthropic: 'claude-haiku-4-5', LlmProvider.openAi: 'gpt-6-luna'},
      tokens: {LlmProvider.anthropic: 'sk-ant-1', LlmProvider.openAi: 'sk-openai-2'},
      baseUrl: 'https://example.test/v1/',
      maxContext: 5,
    );
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response(
        jsonEncode({
          'choices': [
            {'message': {'content': 'Monthly [1]'}},
          ],
          'usage': {'prompt_tokens': 1000, 'completion_tokens': 100},
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    final a = await LlmService(s, client: client).answer('When is rent due?', _hits);

    expect(seen.url.toString(), 'https://example.test/v1/chat/completions');
    expect(seen.headers['authorization'], 'Bearer sk-openai-2');
    final body = jsonDecode(seen.body) as Map;
    expect(body['model'], 'gpt-6-luna');
    expect(jsonEncode(body['messages']), contains('Rent is due monthly.'));
    expect(a.text, 'Monthly [1]');
    expect(a.inputTokens, 1000);
    expect(a.costUsd, closeTo(1000 / 1e6 * 0.10 + 100 / 1e6 * 0.50, 1e-9));
  });

  test('Anthropic request uses its own token; haiku gets no effort param', () async {
    final s = await _settings();
    await s.saveAi(
      provider: LlmProvider.anthropic,
      models: {LlmProvider.anthropic: 'claude-haiku-4-5', LlmProvider.openAi: 'gpt-6-luna'},
      tokens: {LlmProvider.anthropic: 'sk-ant-1', LlmProvider.openAi: 'sk-openai-2'},
      baseUrl: defaultOpenAiBaseUrl,
      maxContext: 5,
    );
    late http.Request seen;
    final client = MockClient((req) async {
      seen = req;
      return http.Response(
        jsonEncode({
          'content': [
            {'type': 'text', 'text': 'Answer'},
          ],
          'usage': {'input_tokens': 10, 'output_tokens': 5},
        }),
        200,
      );
    });
    final a = await LlmService(s, client: client).answer('q', _hits);
    expect(seen.url.host, 'api.anthropic.com');
    expect(seen.headers['x-api-key'], 'sk-ant-1');
    expect((jsonDecode(seen.body) as Map).containsKey('output_config'), isFalse);
    expect(a.text, 'Answer');
  });

  test('API errors surface the server message', () async {
    final s = await _settings();
    final client = MockClient((_) async => http.Response(jsonEncode({'error': {'message': 'bad key'}}), 401));
    expect(
      () => LlmService(s, client: client).answer('q', _hits),
      throwsA(isA<LlmException>().having((e) => e.message, 'message', contains('bad key'))),
    );
  });
}
