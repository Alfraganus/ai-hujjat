// Renders the main screens to PNG files (build/ui_shots) so the design can be
// reviewed without launching the app. Opt in with:
//   UI_SHOTS=1 flutter test test/ui_screenshots_test.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ai_hujjat/app_controller.dart';
import 'package:ai_hujjat/data/database.dart';
import 'package:ai_hujjat/main.dart';
import 'package:ai_hujjat/services/embedder.dart';
import 'package:ai_hujjat/services/llm_catalog.dart';
import 'package:ai_hujjat/services/llm_service.dart';
import 'package:ai_hujjat/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _shotKey = GlobalKey();

Future<void> _loadFonts() async {
  final root = '${Platform.environment['FLUTTER_ROOT'] ?? 'C:/flutter'}/bin/cache/artifacts/material_fonts';
  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final path = '$root/$f';
      if (File(path).existsSync()) loader.addFont(Future.value(ByteData.sublistView(File(path).readAsBytesSync())));
    }
    await loader.load();
  }

  await load('Roboto', ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf', 'roboto-black.ttf', 'roboto-light.ttf']);
  await load('MaterialIcons', ['materialicons-regular.otf']);
}

Future<void> _shot(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  final boundary = tester.firstRenderObject<RenderRepaintBoundary>(find.byKey(_shotKey));
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.0);
    return (await image.toByteData(format: ui.ImageByteFormat.png))!;
  });
  Directory('build/ui_shots').createSync(recursive: true);
  File('build/ui_shots/$name.png').writeAsBytesSync(bytes!.buffer.asUint8List());
}

Future<AppController> _seed({bool aiReady = true}) async {
  SharedPreferences.setMockInitialValues({'locale': 'uz'});
  final settings = await SettingsService.load();
  if (aiReady) {
    await settings.saveAi(
      provider: LlmProvider.anthropic,
      models: {LlmProvider.anthropic: 'claude-haiku-4-5', LlmProvider.openAi: 'gpt-6-luna'},
      tokens: {LlmProvider.anthropic: 'sk-test', LlmProvider.openAi: ''},
      baseUrl: defaultOpenAiBaseUrl,
      maxContext: 5,
    );
  }
  final db = AppDatabase.inMemory();
  final contracts = db.createCategory('Shartnomalar');
  final hr = db.createCategory('HR siyosati');
  final tech = db.createCategory('Texnik hujjatlar');
  final finance = db.createCategory('Moliya va hisobotlar');
  db.createCategory('Qonunchilik');
  db.saveDocument(
    categoryId: contracts,
    title: 'Ijara shartnomasi №14',
    content:
        "Ijarachi har oyning birinchi kunida ijara haqini to'lashi shart. To'lov kechiktirilsa, har bir kechikkan kun uchun 0.5 foiz jarima undiriladi.\n\nShartnoma muddati 11 oy. Muddat tugagach, tomonlar kelishuvi bilan uzaytirilishi mumkin. Ijarachi mol-mulkni ijaraga bermaydi.",
  );
  db.saveDocument(
    categoryId: contracts,
    title: "Xizmat ko'rsatish shartnomasi",
    content: "Pudratchi ishni 30 kalendar kun ichida topshiradi. Qabul qilish dalolatnomasi imzolangandan so'ng 5 bank kuni ichida to'lov amalga oshiriladi.",
  );
  db.saveDocument(
    categoryId: hr,
    title: "Ta'tillar to'g'risidagi nizom",
    content: "Har bir xodim yiliga 28 kalendar kunlik haq to'lanadigan ta'tilga ega. Ta'til jadvali har yili 15 dekabrgacha tasdiqlanadi.",
  );
  db.saveDocument(categoryId: tech, title: "API integratsiya qo'llanmasi", content: "Barcha so'rovlar HTTPS orqali yuboriladi. Avtorizatsiya Bearer token bilan amalga oshiriladi.");
  db.saveDocument(categoryId: finance, title: 'Choraklik hisobot 2026-Q3', content: "Daromad o'tgan chorakka nisbatan 12 foizga oshdi. Xarajatlar rejadan 3 foiz past.");

  final answer = jsonEncode({
    'answer': "Ijara haqi har oyning birinchi kunida to'lanishi shart [1]. Kechiktirilgan har bir kun uchun 0.5 foiz jarima undiriladi [1].",
    'sources': [
      {'id': 1, 'quote': "Ijarachi har oyning birinchi kunida ijara haqini to'lashi shart."},
      {'id': 1, 'quote': 'har bir kechikkan kun uchun 0.5 foiz jarima undiriladi'},
    ],
  });
  final client = MockClient((req) async => http.Response(
        jsonEncode({
          'content': [
            {'type': 'text', 'text': answer},
          ],
          'usage': {'input_tokens': 1480, 'output_tokens': 96},
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ));
  final c = AppController(db, settings, embedder: FakeEmbedder(), llm: LlmService(settings, client: client));
  await c.indexer.run();
  return c;
}

Widget _app(AppController c, {ThemeMode mode = ThemeMode.light}) =>
    RepaintBoundary(key: _shotKey, child: AiHujjatApp(controller: c, fontFamily: 'Roboto', themeMode: mode));

void main() {
  final enabled = Platform.environment['UI_SHOTS'] == '1';

  Future<void> setup(WidgetTester tester, {Size size = const Size(1360, 860)}) async {
    await _loadFonts();
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  testWidgets('shots: light', (tester) async {
    await setup(tester);
    final c = await _seed();
    await tester.pumpWidget(_app(c));
    await _shot(tester, '1_search_hero');

    await tester.tap(find.text('Shartnomalar').first);
    await tester.enterText(find.byType(TextField), "ijara haqi qachon to'lanadi");
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _shot(tester, '2_search_answer');

    await tester.tap(find.textContaining('Manbalar'));
    await _shot(tester, '3_search_sources');

    c.navIndex.value = 0;
    await _shot(tester, '4_categories');
    c.navIndex.value = 1;
    await _shot(tester, '5_documents');
    c.navIndex.value = 3;
    await _shot(tester, '6_settings');
  }, skip: !enabled);

  testWidgets('shots: dark + compact + empty', (tester) async {
    await setup(tester);
    final c = await _seed();
    await tester.pumpWidget(_app(c, mode: ThemeMode.dark));
    await tester.tap(find.text('Shartnomalar').first);
    await tester.enterText(find.byType(TextField), "ijara haqi qachon to'lanadi");
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Manbalar'));
    await _shot(tester, '7_dark_search');
    c.navIndex.value = 3;
    await _shot(tester, '8_dark_settings');

    tester.view.physicalSize = const Size(900, 700);
    c.navIndex.value = 0;
    await _shot(tester, '9_compact_categories');

    SharedPreferences.setMockInitialValues({'locale': 'uz'});
    final empty = AppController(AppDatabase.inMemory(), await SettingsService.load(), embedder: FakeEmbedder());
    await tester.pumpWidget(_app(empty));
    empty.navIndex.value = 1;
    await _shot(tester, '10_empty_documents');
  }, skip: !enabled);
}
