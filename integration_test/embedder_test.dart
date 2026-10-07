import 'dart:math';
import 'dart:typed_data';

import 'package:ai_hujjat/services/embedder.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

double cosine(Float32List a, Float32List b) {
  var d = 0.0;
  for (var i = 0; i < a.length; i++) {
    d += a[i] * b[i];
  }
  return d;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('real e5 model: shape, normalization and multilingual semantics', (tester) async {
    final e = OnnxE5Embedder();
    final sw = Stopwatch()..start();

    final q = await e.embed('Ijara to\'lovi qachon to\'lanadi?', isQuery: true);
    expect(q.length, 384);
    expect(sqrt(q.fold<double>(0, (s, x) => s + x * x)), closeTo(1.0, 1e-3));

    final rent = await e.embed('Ijarachi har oyning birinchi kunida ijara haqini to\'lashi shart.', isQuery: false);
    final rentRu = await e.embed('Арендатор обязан вносить арендную плату в первый день каждого месяца.', isQuery: false);
    final soup = await e.embed('Sabzi va piyozni qovuring, keyin guruch qo\'shing.', isQuery: false);

    final sRent = cosine(q, rent);
    final sRentRu = cosine(q, rentRu);
    final sSoup = cosine(q, soup);
    // ignore: avoid_print
    print('rent(uz)=$sRent rent(ru)=$sRentRu soup=$sSoup  elapsed=${sw.elapsedMilliseconds}ms');

    expect(sRent, greaterThan(sSoup));
    expect(sRentRu, greaterThan(sSoup)); // cross-language match
  });
}
