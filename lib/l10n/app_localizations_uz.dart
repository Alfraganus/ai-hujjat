// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'AI Hujjat';

  @override
  String get navCategories => 'Kategoriyalar';

  @override
  String get navDocuments => 'Hujjatlar';

  @override
  String get navSearch => 'Qidiruv';

  @override
  String get navSettings => 'Sozlamalar';

  @override
  String get add => 'Qo\'shish';

  @override
  String get edit => 'Tahrirlash';

  @override
  String get delete => 'O\'chirish';

  @override
  String get save => 'Saqlash';

  @override
  String get cancel => 'Bekor qilish';

  @override
  String get close => 'Yopish';

  @override
  String get name => 'Nomi';

  @override
  String get required => 'Majburiy';

  @override
  String confirmDelete(String name) {
    return '\"$name\" o\'chirilsinmi?';
  }

  @override
  String get categoryDeleteWarning =>
      'Bu kategoriyadagi barcha hujjatlar ham o\'chiriladi.';

  @override
  String get newCategory => 'Yangi kategoriya';

  @override
  String get editCategory => 'Kategoriyani tahrirlash';

  @override
  String get noCategories => 'Hali kategoriya yo\'q. Birinchisini yarating.';

  @override
  String documentsCount(int count) {
    return '$count ta hujjat';
  }

  @override
  String get allCategories => 'Barcha kategoriyalar';

  @override
  String get category => 'Kategoriya';

  @override
  String get title => 'Sarlavha';

  @override
  String get content => 'Matn';

  @override
  String get addDocument => 'Hujjat qo\'shish';

  @override
  String get importFile => 'Fayldan yuklash (.txt, .md, .pdf, .docx)';

  @override
  String indexingProgress(int count) {
    return 'Ma\'no bo\'yicha qidiruv uchun hujjatlar indekslanmoqda: $count ta qoldi';
  }

  @override
  String get semanticUnavailable =>
      'Ma\'no bo\'yicha qidiruv ishlamayapti (embedding modeli topilmadi). Faqat so\'z bo\'yicha qidiriladi.';

  @override
  String get importEmpty =>
      'Faylda matn topilmadi. Skaner qilingan (rasm) PDF\'lar hali qo\'llab-quvvatlanmaydi.';

  @override
  String importFailed(String error) {
    return 'Faylni o\'qib bo\'lmadi: $error';
  }

  @override
  String get editDocument => 'Hujjatni tahrirlash';

  @override
  String get noDocuments => 'Bu kategoriyada hujjat yo\'q.';

  @override
  String get selectCategoryFirst => 'Avval kategoriya yarating.';

  @override
  String get searchHint => 'Hujjatlar ichidan qidirish...';

  @override
  String get searchInCategory => 'Kategoriya bo\'yicha qidirish';

  @override
  String get aiAnswer => 'AI javobi';

  @override
  String sourcesCount(int count) {
    return 'Manbalar ($count)';
  }

  @override
  String get usedByAi => 'AI ishlatgan';

  @override
  String get copy => 'Nusxalash';

  @override
  String get copied => 'Nusxalandi';

  @override
  String get searchPrompt =>
      'Tanlangan kategoriyadagi hujjatlar bo\'yicha savol bering.';

  @override
  String get appTagline => 'Offline hujjat qidiruvi';

  @override
  String get aiReady => 'AI tayyor';

  @override
  String get aiSetupNeeded => 'AI sozlanmagan';

  @override
  String get aiSetupHint => 'Sozlamalarda API token kiriting';

  @override
  String indexingShort(int count) {
    return 'Indekslanmoqda: $count ta qoldi';
  }

  @override
  String get categoriesEmptyHint =>
      'Kategoriyalar hujjatlarni guruhlaydi. Qidiruvni bitta kategoriya bilan cheklash mumkin.';

  @override
  String get documentsEmptyHint =>
      'Matn qo\'shing yoki PDF, DOCX, TXT, MD faylni yuklang.';

  @override
  String get noResultsHint =>
      'Boshqa so\'zlar bilan urinib ko\'ring yoki barcha kategoriyalardan qidiring.';

  @override
  String get searchHeroTitle => 'Hujjatlaringizdan so\'rang';

  @override
  String get clear => 'Tozalash';

  @override
  String usedByAiCount(int count) {
    return '$count tasini AI ishlatgan';
  }

  @override
  String get settingsCheapest => 'Eng arzon';

  @override
  String get settingsDefault => 'Standart';

  @override
  String get noResults => 'Hech narsa topilmadi.';

  @override
  String get searching => 'Qidirilmoqda...';

  @override
  String get aiThinking => 'AI javob tayyorlamoqda...';

  @override
  String get aiNotConfigured =>
      'Avval Sozlamalarda AI provayder va tokenni kiriting.';

  @override
  String aiError(String error) {
    return 'AI so\'rovida xatolik: $error';
  }

  @override
  String get settingsLanguage => 'Til';

  @override
  String get settingsAi => 'AI model';

  @override
  String get settingsProvider => 'Provayder';

  @override
  String get settingsModel => 'Model';

  @override
  String get settingsCustomModel => 'Model ID';

  @override
  String get settingsBaseUrl => 'Base URL';

  @override
  String get settingsToken => 'API token';

  @override
  String get settingsTokenHint => 'Shu kompyuterda xavfsiz saqlanadi';

  @override
  String get settingsShowToken => 'Tokenni ko\'rsatish';

  @override
  String get settingsSaved => 'Sozlamalar saqlandi';

  @override
  String get settingsTokenMissing => 'Token yo\'q';

  @override
  String get settingsTokenSet => 'Token saqlangan';

  @override
  String get settingsOfflineNote =>
      'Hujjatlar, kategoriyalar va qidiruv to\'liq offline ishlaydi. Faqat \"AI\'dan so\'rash\" bosilganda topilgan parchalar tanlangan provayderga yuboriladi.';

  @override
  String get settingsMaxContext => 'AI\'ga yuboriladigan parchalar soni';

  @override
  String get providerAnthropic => 'Anthropic (Claude)';

  @override
  String get providerOpenAi => 'OpenAI (va mos serverlar)';

  @override
  String get settingsPriceHint =>
      'Narxlar USD\'da, 1M token uchun: kirish / chiqish. Arzondan qimmatga tartiblangan.';

  @override
  String get settingsBaseUrlHint =>
      'Faqat OpenAI-mos serverlar uchun o\'zgartiring.';

  @override
  String get customModel => 'Boshqa...';
}
