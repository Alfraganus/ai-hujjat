// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'AI Hujjat';

  @override
  String get navCategories => 'Категории';

  @override
  String get navDocuments => 'Документы';

  @override
  String get navSearch => 'Поиск';

  @override
  String get navSettings => 'Настройки';

  @override
  String get add => 'Добавить';

  @override
  String get edit => 'Изменить';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get cancel => 'Отмена';

  @override
  String get close => 'Закрыть';

  @override
  String get name => 'Название';

  @override
  String get required => 'Обязательно';

  @override
  String confirmDelete(String name) {
    return 'Удалить «$name»?';
  }

  @override
  String get categoryDeleteWarning =>
      'Все документы в этой категории тоже будут удалены.';

  @override
  String get newCategory => 'Новая категория';

  @override
  String get editCategory => 'Изменить категорию';

  @override
  String get noCategories => 'Категорий пока нет. Создайте первую.';

  @override
  String documentsCount(int count) {
    return 'Документов: $count';
  }

  @override
  String get allCategories => 'Все категории';

  @override
  String get category => 'Категория';

  @override
  String get title => 'Заголовок';

  @override
  String get content => 'Текст';

  @override
  String get addDocument => 'Добавить документ';

  @override
  String get importFile => 'Загрузить из файла (.txt, .md, .pdf, .docx)';

  @override
  String indexingProgress(int count) {
    return 'Индексация документов для семантического поиска: осталось $count';
  }

  @override
  String get semanticUnavailable =>
      'Семантический поиск недоступен (модель эмбеддингов не найдена). Используется только поиск по словам.';

  @override
  String get importEmpty =>
      'В файле не найден текст. PDF-сканы (изображения) пока не поддерживаются.';

  @override
  String importFailed(String error) {
    return 'Не удалось прочитать файл: $error';
  }

  @override
  String get editDocument => 'Изменить документ';

  @override
  String get noDocuments => 'В этой категории нет документов.';

  @override
  String get selectCategoryFirst => 'Сначала создайте категорию.';

  @override
  String get searchHint => 'Поиск по документам...';

  @override
  String get searchInCategory => 'Поиск по категории';

  @override
  String get aiAnswer => 'Ответ ИИ';

  @override
  String sourcesCount(int count) {
    return 'Источники ($count)';
  }

  @override
  String get usedByAi => 'Использовано ИИ';

  @override
  String get copy => 'Копировать';

  @override
  String get copied => 'Скопировано';

  @override
  String get searchPrompt =>
      'Задайте вопрос по документам выбранной категории.';

  @override
  String get appTagline => 'Офлайн-поиск по документам';

  @override
  String get aiReady => 'ИИ готов';

  @override
  String get aiSetupNeeded => 'ИИ не настроен';

  @override
  String get aiSetupHint => 'Добавьте API-токен в настройках';

  @override
  String indexingShort(int count) {
    return 'Индексация: осталось $count';
  }

  @override
  String get categoriesEmptyHint =>
      'Категории группируют документы. Поиск можно ограничить одной категорией.';

  @override
  String get documentsEmptyHint =>
      'Добавьте текст или загрузите файл PDF, DOCX, TXT, MD.';

  @override
  String get noResultsHint =>
      'Попробуйте другие слова или поищите по всем категориям.';

  @override
  String get searchHeroTitle => 'Спросите свои документы';

  @override
  String get clear => 'Очистить';

  @override
  String usedByAiCount(int count) {
    return 'Использовано ИИ: $count';
  }

  @override
  String get settingsCheapest => 'Самая дешёвая';

  @override
  String get settingsDefault => 'По умолчанию';

  @override
  String get noResults => 'Ничего не найдено.';

  @override
  String get searching => 'Поиск...';

  @override
  String get aiThinking => 'ИИ готовит ответ...';

  @override
  String get aiNotConfigured =>
      'Сначала укажите провайдера ИИ и токен в настройках.';

  @override
  String aiError(String error) {
    return 'Ошибка запроса к ИИ: $error';
  }

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsAi => 'Модель ИИ';

  @override
  String get settingsProvider => 'Провайдер';

  @override
  String get settingsModel => 'Модель';

  @override
  String get settingsCustomModel => 'ID модели';

  @override
  String get settingsBaseUrl => 'Base URL';

  @override
  String get settingsToken => 'API-токен';

  @override
  String get settingsTokenHint => 'Хранится безопасно на этом компьютере';

  @override
  String get settingsShowToken => 'Показать токен';

  @override
  String get settingsSaved => 'Настройки сохранены';

  @override
  String get settingsTokenMissing => 'Токена нет';

  @override
  String get settingsTokenSet => 'Токен сохранён';

  @override
  String get settingsOfflineNote =>
      'Документы, категории и поиск работают полностью офлайн. Только «Спросить ИИ» отправляет найденные фрагменты выбранному провайдеру.';

  @override
  String get settingsMaxContext => 'Фрагментов, отправляемых ИИ';

  @override
  String get providerAnthropic => 'Anthropic (Claude)';

  @override
  String get providerOpenAi => 'OpenAI (и совместимые серверы)';

  @override
  String get settingsPriceHint =>
      'Цены в USD за 1M токенов: вход / выход. От дешёвых к дорогим.';

  @override
  String get settingsBaseUrlHint =>
      'Меняйте только для OpenAI-совместимых серверов.';

  @override
  String get customModel => 'Другая...';
}
