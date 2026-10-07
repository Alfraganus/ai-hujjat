import 'dart:convert';

import 'package:ai_hujjat/app_controller.dart';
import 'package:ai_hujjat/data/database.dart';
import 'package:ai_hujjat/main.dart';
import 'package:ai_hujjat/services/embedder.dart';
import 'package:ai_hujjat/services/llm_catalog.dart';
import 'package:ai_hujjat/services/llm_service.dart';
import 'package:ai_hujjat/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _quote = 'pay rent on the first day of each month';

Future<AppController> _controller({required bool configured, required http.Client client}) async {
  SharedPreferences.setMockInitialValues({'locale': 'en'});
  final settings = await SettingsService.load();
  if (configured) {
    await settings.saveAi(
      provider: LlmProvider.openAi,
      models: {LlmProvider.anthropic: 'claude-haiku-4-5', LlmProvider.openAi: 'gpt-6-luna'},
      tokens: {LlmProvider.anthropic: '', LlmProvider.openAi: 'sk-test'},
      baseUrl: defaultOpenAiBaseUrl,
      maxContext: 5,
    );
  }
  final db = AppDatabase.inMemory();
  final law = db.createCategory('Law');
  db.saveDocument(categoryId: law, title: 'Lease', content: 'The tenant must $_quote. Late payment costs 5 percent.');
  final c = AppController(db, settings, embedder: FakeEmbedder(), llm: LlmService(settings, client: client));
  await c.indexer.run();
  return c;
}

http.Client _llmReturning(String content, {List<http.Request>? seen}) => MockClient((req) async {
      seen?.add(req);
      return http.Response(
        jsonEncode({
          'choices': [
            {'message': {'content': content}},
          ],
          'usage': {'prompt_tokens': 500, 'completion_tokens': 50},
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });

/// True if some selectable text has a highlighted span whose text is exactly [text].
bool _hasHighlight(WidgetTester tester, String text) {
  var found = false;
  for (final w in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
    w.textSpan?.visitChildren((span) {
      if (span is TextSpan && span.text == text && span.style?.backgroundColor != null) found = true;
      return true;
    });
  }
  return found;
}

void main() {
  testWidgets('one search shows the AI answer and highlights the quoted place in the sources', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final seen = <http.Request>[];
    final answer = jsonEncode({
      'answer': 'Rent is due on the first of the month [1].',
      'sources': [
        {'id': 1, 'quote': _quote},
      ],
    });
    final controller = await _controller(configured: true, client: _llmReturning(answer, seen: seen));
    await tester.pumpWidget(AiHujjatApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'when is rent due');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    // The AI was called automatically with the retrieved excerpt.
    expect(seen, hasLength(1));
    expect(seen.single.body, contains('The tenant must'));
    expect(find.textContaining('Rent is due on the first of the month', findRichText: true), findsOneWidget);
    expect(find.textContaining('500 in · 50 out'), findsOneWidget);

    // Sources are an accordion: collapsed until the user opens it.
    expect(find.text('Sources (1)'), findsOneWidget);
    expect(find.text('Used by AI'), findsNothing);
    await tester.tap(find.text('Sources (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Used by AI'), findsOneWidget);
    expect(_hasHighlight(tester, _quote), isTrue);
  });

  testWidgets('without an AI token the passages are shown directly and no request is sent', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final seen = <http.Request>[];
    final controller = await _controller(configured: false, client: _llmReturning('{}', seen: seen));
    await tester.pumpWidget(AiHujjatApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'rent');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(seen, isEmpty);
    expect(find.textContaining('Set up the AI provider'), findsOneWidget);
    expect(find.text('Lease'), findsOneWidget); // accordion open, passage listed
    expect(_hasHighlight(tester, 'rent'), isTrue); // search word highlighted instead
  });

  testWidgets('a query with no words means no AI call', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final seen = <http.Request>[];
    final controller = await _controller(configured: true, client: _llmReturning('{}', seen: seen));
    await tester.pumpWidget(AiHujjatApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '???');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(seen, isEmpty);
    expect(find.text('Nothing found.'), findsOneWidget);
  });
}
