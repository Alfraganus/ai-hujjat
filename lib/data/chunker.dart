/// Splits text into overlapping chunks, preferring paragraph boundaries.
List<String> chunkText(String text, {int maxChars = 900, int overlap = 150}) {
  final normalized = text.replaceAll('\r\n', '\n').trim();
  if (normalized.isEmpty) return const [];
  if (normalized.length <= maxChars) return [normalized];

  final pieces = <String>[];
  for (final para in normalized.split(RegExp(r'\n\s*\n'))) {
    final p = para.trim();
    if (p.isEmpty) continue;
    if (p.length <= maxChars) {
      pieces.add(p);
    } else {
      // Very long paragraph: cut on sentence-ish boundaries.
      var start = 0;
      while (start < p.length) {
        var end = start + maxChars;
        if (end < p.length) {
          final cut = p.lastIndexOf(RegExp(r'[.!?\n]\s'), end);
          if (cut > start + maxChars ~/ 2) end = cut + 1;
        } else {
          end = p.length;
        }
        pieces.add(p.substring(start, end).trim());
        start = end;
      }
    }
  }

  final chunks = <String>[];
  var current = StringBuffer();
  for (final piece in pieces) {
    if (current.isNotEmpty && current.length + piece.length + 2 > maxChars) {
      final done = current.toString();
      chunks.add(done);
      final tail = done.length > overlap ? done.substring(done.length - overlap) : done;
      current = StringBuffer(tail);
    }
    if (current.isNotEmpty) current.write('\n\n');
    current.write(piece);
  }
  if (current.isNotEmpty) chunks.add(current.toString());
  return chunks;
}
