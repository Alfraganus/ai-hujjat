import 'package:ai_hujjat/services/llm_service.dart';
import 'package:ai_hujjat/services/quote_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseStructuredAnswer', () {
    test('reads the JSON shape, merges quotes per source and ignores bad ids', () {
      const raw = '{"answer":"Pay monthly [1][2].","sources":['
          '{"id":1,"quote":"pay rent monthly"},{"id":1,"quote":"first day"},'
          '{"id":2,"quote":"late fee"},{"id":9,"quote":"out of range"}]}';
      final r = parseStructuredAnswer(raw, 3);
      expect(r.answer, 'Pay monthly [1][2].');
      expect(r.sources.map((s) => s.index), [0, 1]);
      expect(r.sources[0].quotes, ['pay rent monthly', 'first day']);
      expect(r.sources[1].quotes, ['late fee']);
    });

    test('tolerates code fences and surrounding prose', () {
      const raw = 'Here you go:\n```json\n{"answer":"Yes [2]","sources":[{"id":2,"quote":"it is allowed"}]}\n```';
      final r = parseStructuredAnswer(raw, 2);
      expect(r.answer, 'Yes [2]');
      expect(r.sources.single.index, 1);
    });

    test('adds sources that are cited inline but missing from the list', () {
      final r = parseStructuredAnswer('{"answer":"See [1] and [3].","sources":[{"id":1,"quote":"abc def"}]}', 3);
      expect(r.sources.map((s) => s.index), [0, 2]);
      expect(r.sources[1].quotes, isEmpty);
    });

    test('plain text falls back to inline citations', () {
      final r = parseStructuredAnswer('The rent is due monthly [2].', 3);
      expect(r.answer, 'The rent is due monthly [2].');
      expect(r.sources.map((s) => s.index), [1]);
    });

    test('"not found" answer has no sources', () {
      final r = parseStructuredAnswer('{"answer":"The excerpts do not say.","sources":[]}', 3);
      expect(r.sources, isEmpty);
    });
  });

  group('findQuoteRanges', () {
    const text = 'Intro.\nThe tenant must pay rent\non the first day of each month.\n\nOther text here.';

    test('matches across different whitespace and case', () {
      final r = findQuoteRanges(text, ['pay RENT on   the first day']);
      expect(r, hasLength(1));
      expect(text.substring(r.first.start, r.first.end), 'pay rent\non the first day');
    });

    test('ellipsis quotes match piece by piece and quotes are trimmed', () {
      final r = findQuoteRanges(text, ['"The tenant must pay rent … each month."']);
      expect(r, hasLength(2));
      expect(text.substring(r[0].start, r[0].end), 'The tenant must pay rent');
      expect(text.substring(r[1].start, r[1].end), 'each month.');
    });

    test('unmatched or tiny quotes are skipped; overlaps merge', () {
      expect(findQuoteRanges(text, ['something else entirely', 'a']), isEmpty);
      final merged = findQuoteRanges(text, ['tenant must pay rent', 'pay rent on the first']);
      expect(merged, hasLength(1));
      expect(text.substring(merged.first.start, merged.first.end), 'tenant must pay rent\non the first');
    });
  });
}
