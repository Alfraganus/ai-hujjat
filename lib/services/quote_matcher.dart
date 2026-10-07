/// A half-open character range [start, end) inside a text.
class TextRange2 {
  const TextRange2(this.start, this.end);
  final int start;
  final int end;
}

/// Finds where the AI's [quotes] occur in [text].
///
/// Models rarely copy whitespace exactly, so matching ignores case and treats
/// any run of whitespace as equal. Quotes containing "…" / "..." are matched
/// piece by piece. Returns non-overlapping ranges sorted by position; quotes
/// that cannot be located are skipped.
List<TextRange2> findQuoteRanges(String text, Iterable<String> quotes) {
  final found = <TextRange2>[];
  for (final quote in quotes) {
    for (final piece in quote.split(RegExp(r'…|\.{3}'))) {
      final words = piece
          .replaceAll(RegExp('^[\\s"“”«»\']+|[\\s"“”«»\']+\$'), '')
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (words.isEmpty || words.join(' ').length < 6) continue;
      final re = RegExp(words.map(RegExp.escape).join(r'\s+'), caseSensitive: false, unicode: true);
      final m = re.firstMatch(text);
      if (m != null) found.add(TextRange2(m.start, m.end));
    }
  }
  found.sort((a, b) => a.start.compareTo(b.start));

  // Merge overlaps so highlighting never double-covers text.
  final merged = <TextRange2>[];
  for (final r in found) {
    if (merged.isNotEmpty && r.start <= merged.last.end) {
      final last = merged.removeLast();
      merged.add(TextRange2(last.start, r.end > last.end ? r.end : last.end));
    } else {
      merged.add(r);
    }
  }
  return merged;
}
