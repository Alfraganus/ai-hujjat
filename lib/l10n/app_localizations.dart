import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_uz.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru'),
    Locale('uz'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Hujjat'**
  String get appTitle;

  /// No description provided for @navCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// No description provided for @navDocuments.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get navDocuments;

  /// No description provided for @navSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String confirmDelete(String name);

  /// No description provided for @categoryDeleteWarning.
  ///
  /// In en, this message translates to:
  /// **'All documents inside this category will be deleted too.'**
  String get categoryDeleteWarning;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @noCategories.
  ///
  /// In en, this message translates to:
  /// **'No categories yet. Create the first one.'**
  String get noCategories;

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} documents'**
  String documentsCount(int count);

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get title;

  /// No description provided for @content.
  ///
  /// In en, this message translates to:
  /// **'Content'**
  String get content;

  /// No description provided for @addDocument.
  ///
  /// In en, this message translates to:
  /// **'Add document'**
  String get addDocument;

  /// No description provided for @importFile.
  ///
  /// In en, this message translates to:
  /// **'Import file (.txt, .md, .pdf, .docx)'**
  String get importFile;

  /// No description provided for @indexingProgress.
  ///
  /// In en, this message translates to:
  /// **'Indexing documents for semantic search: {count} left'**
  String indexingProgress(int count);

  /// No description provided for @semanticUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Semantic search is unavailable (embedding model not found). Using keyword search only.'**
  String get semanticUnavailable;

  /// No description provided for @importEmpty.
  ///
  /// In en, this message translates to:
  /// **'No text found in this file. Scanned PDFs (images) are not supported yet.'**
  String get importEmpty;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not read the file: {error}'**
  String importFailed(String error);

  /// No description provided for @editDocument.
  ///
  /// In en, this message translates to:
  /// **'Edit document'**
  String get editDocument;

  /// No description provided for @noDocuments.
  ///
  /// In en, this message translates to:
  /// **'No documents in this category.'**
  String get noDocuments;

  /// No description provided for @selectCategoryFirst.
  ///
  /// In en, this message translates to:
  /// **'Create a category first.'**
  String get selectCategoryFirst;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search in documents...'**
  String get searchHint;

  /// No description provided for @searchInCategory.
  ///
  /// In en, this message translates to:
  /// **'Search in category'**
  String get searchInCategory;

  /// No description provided for @aiAnswer.
  ///
  /// In en, this message translates to:
  /// **'AI answer'**
  String get aiAnswer;

  /// No description provided for @sourcesCount.
  ///
  /// In en, this message translates to:
  /// **'Sources ({count})'**
  String sourcesCount(int count);

  /// No description provided for @usedByAi.
  ///
  /// In en, this message translates to:
  /// **'Used by AI'**
  String get usedByAi;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Ask a question about the documents in the selected category.'**
  String get searchPrompt;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Offline document search'**
  String get appTagline;

  /// No description provided for @aiReady.
  ///
  /// In en, this message translates to:
  /// **'AI is ready'**
  String get aiReady;

  /// No description provided for @aiSetupNeeded.
  ///
  /// In en, this message translates to:
  /// **'AI not set up'**
  String get aiSetupNeeded;

  /// No description provided for @aiSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Add an API token in Settings'**
  String get aiSetupHint;

  /// No description provided for @indexingShort.
  ///
  /// In en, this message translates to:
  /// **'Indexing: {count} left'**
  String indexingShort(int count);

  /// No description provided for @categoriesEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Categories group your documents. Search can be limited to a single category.'**
  String get categoriesEmptyHint;

  /// No description provided for @documentsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add text or import a PDF, DOCX, TXT or MD file.'**
  String get documentsEmptyHint;

  /// No description provided for @noResultsHint.
  ///
  /// In en, this message translates to:
  /// **'Try different words, or search in all categories.'**
  String get noResultsHint;

  /// No description provided for @searchHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask your documents'**
  String get searchHeroTitle;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @usedByAiCount.
  ///
  /// In en, this message translates to:
  /// **'{count} used by AI'**
  String usedByAiCount(int count);

  /// No description provided for @settingsCheapest.
  ///
  /// In en, this message translates to:
  /// **'Cheapest'**
  String get settingsCheapest;

  /// No description provided for @settingsDefault.
  ///
  /// In en, this message translates to:
  /// **'Default'**
  String get settingsDefault;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'Nothing found.'**
  String get noResults;

  /// No description provided for @searching.
  ///
  /// In en, this message translates to:
  /// **'Searching...'**
  String get searching;

  /// No description provided for @aiThinking.
  ///
  /// In en, this message translates to:
  /// **'AI is answering...'**
  String get aiThinking;

  /// No description provided for @aiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'Set up the AI provider and API token in Settings first.'**
  String get aiNotConfigured;

  /// No description provided for @aiError.
  ///
  /// In en, this message translates to:
  /// **'AI request failed: {error}'**
  String aiError(String error);

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsAi.
  ///
  /// In en, this message translates to:
  /// **'AI model'**
  String get settingsAi;

  /// No description provided for @settingsProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get settingsProvider;

  /// No description provided for @settingsModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get settingsModel;

  /// No description provided for @settingsCustomModel.
  ///
  /// In en, this message translates to:
  /// **'Model ID'**
  String get settingsCustomModel;

  /// No description provided for @settingsBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get settingsBaseUrl;

  /// No description provided for @settingsToken.
  ///
  /// In en, this message translates to:
  /// **'API token'**
  String get settingsToken;

  /// No description provided for @settingsTokenHint.
  ///
  /// In en, this message translates to:
  /// **'Stored securely on this computer'**
  String get settingsTokenHint;

  /// No description provided for @settingsShowToken.
  ///
  /// In en, this message translates to:
  /// **'Show token'**
  String get settingsShowToken;

  /// No description provided for @settingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved'**
  String get settingsSaved;

  /// No description provided for @settingsTokenMissing.
  ///
  /// In en, this message translates to:
  /// **'No token'**
  String get settingsTokenMissing;

  /// No description provided for @settingsTokenSet.
  ///
  /// In en, this message translates to:
  /// **'Token saved'**
  String get settingsTokenSet;

  /// No description provided for @settingsOfflineNote.
  ///
  /// In en, this message translates to:
  /// **'Documents, categories and search work fully offline. Only \"Ask AI\" sends the found excerpts to the selected provider.'**
  String get settingsOfflineNote;

  /// No description provided for @settingsMaxContext.
  ///
  /// In en, this message translates to:
  /// **'Excerpts sent to AI'**
  String get settingsMaxContext;

  /// No description provided for @providerAnthropic.
  ///
  /// In en, this message translates to:
  /// **'Anthropic (Claude)'**
  String get providerAnthropic;

  /// No description provided for @providerOpenAi.
  ///
  /// In en, this message translates to:
  /// **'OpenAI (and compatible servers)'**
  String get providerOpenAi;

  /// No description provided for @settingsPriceHint.
  ///
  /// In en, this message translates to:
  /// **'Prices in USD per 1M tokens: input / output. Sorted cheapest first.'**
  String get settingsPriceHint;

  /// No description provided for @settingsBaseUrlHint.
  ///
  /// In en, this message translates to:
  /// **'Change only for OpenAI-compatible servers.'**
  String get settingsBaseUrlHint;

  /// No description provided for @customModel.
  ///
  /// In en, this message translates to:
  /// **'Custom...'**
  String get customModel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru', 'uz'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
    case 'uz':
      return AppLocalizationsUz();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
