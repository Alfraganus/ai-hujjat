import 'package:flutter/foundation.dart';

import '../data/database.dart';
import '../data/models.dart';
import 'app_log.dart';
import 'embedder.dart';

/// Fills in embeddings for chunks in the background and reports progress.
class IndexingService extends ChangeNotifier {
  IndexingService(this._db, this._embedder);

  final AppDatabase _db;
  final Embedder _embedder;

  int pending = 0;
  bool running = false;
  String? error;
  bool _again = false;

  void refreshPending() {
    pending = _db.pendingEmbeddingCount(_embedder.modelId);
    notifyListeners();
  }

  /// Embeds every chunk that still lacks a vector. Safe to call repeatedly;
  /// calls made while a run is in progress cause one more pass afterwards.
  Future<void> run() async {
    if (running) {
      _again = true;
      return;
    }
    running = true;
    error = null;
    refreshPending();
    AppLog.write('indexing start, pending=$pending');
    try {
      do {
        _again = false;
        while (true) {
          final batch = _db.chunksNeedingEmbedding(_embedder.modelId);
          if (batch.isEmpty) break;
          for (final c in batch) {
            final v = await _embedder.embed(c.text, isQuery: false);
            _db.saveEmbedding(c.id, _embedder.modelId, v);
            pending = (pending - 1).clamp(0, 1 << 30);
            notifyListeners();
          }
        }
      } while (_again);
      AppLog.write('indexing done');
    } catch (e, st) {
      error = e.toString();
      AppLog.write('indexing failed: $e\n$st');
    } finally {
      running = false;
      refreshPending();
    }
  }
}

/// Hybrid search: keyword (FTS5/BM25) + semantic (embeddings), merged with
/// Reciprocal Rank Fusion. Falls back to keyword-only if the model is missing.
class SearchService {
  SearchService(this._db, this._embedder);

  final AppDatabase _db;
  final Embedder _embedder;

  /// Set when the last search could not use the semantic part.
  String? semanticError;

  Future<List<SearchHit>> search(String query, {int? categoryId, int limit = 8}) async {
    // Punctuation-only input ("???") has nothing to search for; embedding it
    // would still return "nearest" chunks and trigger a pointless AI call.
    if (queryTerms(query).isEmpty) return const [];
    final keyword = _db.search(query, categoryId: categoryId, limit: 20);

    var semantic = const <SearchHit>[];
    semanticError = null;
    try {
      final q = await _embedder.embed(query, isQuery: true);
      semantic = _db.vectorSearch(q, _embedder.modelId, categoryId: categoryId, limit: 20);
    } catch (e) {
      semanticError = e.toString();
    }
    return reciprocalRankFusion([keyword, semantic]).take(limit).toList();
  }
}

/// Merges ranked lists; items ranked high in several lists rise to the top.
List<SearchHit> reciprocalRankFusion(List<List<SearchHit>> lists, {int k = 60}) {
  final scores = <int, double>{};
  final byId = <int, SearchHit>{};
  for (final list in lists) {
    for (var rank = 0; rank < list.length; rank++) {
      final hit = list[rank];
      byId[hit.chunkId] = hit;
      scores[hit.chunkId] = (scores[hit.chunkId] ?? 0) + 1 / (k + rank + 1);
    }
  }
  final ids = scores.keys.toList()..sort((a, b) => scores[b]!.compareTo(scores[a]!));
  return [for (final id in ids) byId[id]!];
}
