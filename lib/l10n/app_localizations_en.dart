// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AI Hujjat';

  @override
  String get navCategories => 'Categories';

  @override
  String get navDocuments => 'Documents';

  @override
  String get navSearch => 'Search';

  @override
  String get navSettings => 'Settings';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get close => 'Close';

  @override
  String get name => 'Name';

  @override
  String get required => 'Required';

  @override
  String confirmDelete(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get categoryDeleteWarning =>
      'All documents inside this category will be deleted too.';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get noCategories => 'No categories yet. Create the first one.';

  @override
  String documentsCount(int count) {
    return '$count documents';
  }

  @override
  String get allCategories => 'All categories';

  @override
  String get category => 'Category';

  @override
  String get title => 'Title';

  @override
  String get content => 'Content';

  @override
  String get addDocument => 'Add document';

  @override
  String get importFile => 'Import file (.txt, .md, .pdf, .docx)';

  @override
  String indexingProgress(int count) {
    return 'Indexing documents for semantic search: $count left';
  }

  @override
  String get semanticUnavailable =>
      'Semantic search is unavailable (embedding model not found). Using keyword search only.';

  @override
  String get importEmpty =>
      'No text found in this file. Scanned PDFs (images) are not supported yet.';

  @override
  String importFailed(String error) {
    return 'Could not read the file: $error';
  }

  @override
  String get editDocument => 'Edit document';

  @override
  String get noDocuments => 'No documents in this category.';

  @override
  String get selectCategoryFirst => 'Create a category first.';

  @override
  String get searchHint => 'Search in documents...';

  @override
  String get searchInCategory => 'Search in category';

  @override
  String get aiAnswer => 'AI answer';

  @override
  String sourcesCount(int count) {
    return 'Sources ($count)';
  }

  @override
  String get usedByAi => 'Used by AI';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get searchPrompt =>
      'Ask a question about the documents in the selected category.';

  @override
  String get appTagline => 'Offline document search';

  @override
  String get aiReady => 'AI is ready';

  @override
  String get aiSetupNeeded => 'AI not set up';

  @override
  String get aiSetupHint => 'Add an API token in Settings';

  @override
  String indexingShort(int count) {
    return 'Indexing: $count left';
  }

  @override
  String get categoriesEmptyHint =>
      'Categories group your documents. Search can be limited to a single category.';

  @override
  String get documentsEmptyHint =>
      'Add text or import a PDF, DOCX, TXT or MD file.';

  @override
  String get noResultsHint =>
      'Try different words, or search in all categories.';

  @override
  String get searchHeroTitle => 'Ask your documents';

  @override
  String get clear => 'Clear';

  @override
  String usedByAiCount(int count) {
    return '$count used by AI';
  }

  @override
  String get settingsCheapest => 'Cheapest';

  @override
  String get settingsDefault => 'Default';

  @override
  String get noResults => 'Nothing found.';

  @override
  String get searching => 'Searching...';

  @override
  String get aiThinking => 'AI is answering...';

  @override
  String get aiNotConfigured =>
      'Set up the AI provider and API token in Settings first.';

  @override
  String aiError(String error) {
    return 'AI request failed: $error';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAi => 'AI model';

  @override
  String get settingsProvider => 'Provider';

  @override
  String get settingsModel => 'Model';

  @override
  String get settingsCustomModel => 'Model ID';

  @override
  String get settingsBaseUrl => 'Base URL';

  @override
  String get settingsToken => 'API token';

  @override
  String get settingsTokenHint => 'Stored securely on this computer';

  @override
  String get settingsShowToken => 'Show token';

  @override
  String get settingsSaved => 'Settings saved';

  @override
  String get settingsTokenMissing => 'No token';

  @override
  String get settingsTokenSet => 'Token saved';

  @override
  String get settingsOfflineNote =>
      'Documents, categories and search work fully offline. Only \"Ask AI\" sends the found excerpts to the selected provider.';

  @override
  String get settingsMaxContext => 'Excerpts sent to AI';

  @override
  String get providerAnthropic => 'Anthropic (Claude)';

  @override
  String get providerOpenAi => 'OpenAI (and compatible servers)';

  @override
  String get settingsPriceHint =>
      'Prices in USD per 1M tokens: input / output. Sorted cheapest first.';

  @override
  String get settingsBaseUrlHint =>
      'Change only for OpenAI-compatible servers.';

  @override
  String get customModel => 'Custom...';
}
