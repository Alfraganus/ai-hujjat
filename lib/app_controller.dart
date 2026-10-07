import 'package:flutter/widgets.dart';

import 'data/database.dart';
import 'data/models.dart';
import 'services/embedder.dart';
import 'services/llm_service.dart';
import 'services/search_service.dart';
import 'services/settings_service.dart';

/// Holds the database, settings and shared UI state (categories, selection).
class AppController extends ChangeNotifier {
  AppController(this.db, this.settings, {Embedder? embedder, LlmService? llm})
      : llm = llm ?? LlmService(settings),
        embedder = embedder ?? OnnxE5Embedder() {
    categories = db.categories();
    indexer = IndexingService(db, this.embedder);
    searchService = SearchService(db, this.embedder);
    // Index anything that has no vectors yet (new install, imported data).
    indexer.refreshPending();
    if (indexer.pending > 0) indexer.run();
  }

  final AppDatabase db;
  final SettingsService settings;
  final LlmService llm;
  final Embedder embedder;
  late final IndexingService indexer;
  late final SearchService searchService;

  late List<Category> categories;

  /// Selected sidebar page (0 categories, 1 documents, 2 search, 3 settings).
  final ValueNotifier<int> navIndex = ValueNotifier(2);

  /// Bumped whenever documents change so list pages can refresh.
  int documentsRevision = 0;

  void refresh({bool documentsChanged = false}) {
    categories = db.categories();
    if (documentsChanged) {
      documentsRevision++;
      indexer.run(); // embed new/edited chunks in the background
    }
    notifyListeners();
  }
}

class AppScope extends InheritedNotifier<AppController> {
  const AppScope({super.key, required AppController controller, required super.child})
      : super(notifier: controller);

  static AppController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
