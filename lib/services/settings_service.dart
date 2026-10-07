import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'llm_catalog.dart';
import 'secret_store.dart';

/// App settings. The model and API token are remembered per provider, so
/// switching provider never sends one vendor's key to another.
class SettingsService extends ChangeNotifier {
  SettingsService._(this._prefs, this._secrets);

  final SharedPreferences _prefs;
  final SecretStore _secrets;

  static const _kLocale = 'locale';
  static const _kProvider = 'provider';
  static const _kBaseUrl = 'base_url';
  static const _kMaxContext = 'max_context';
  static const _kLegacyToken = 'api_token'; // single shared token before per-provider tokens
  static const _kLegacyModel = 'model';

  static String _modelKey(LlmProvider p) => 'model_${p.id}';
  static String _tokenKey(LlmProvider p) => 'api_token_${p.id}';

  final _tokens = <LlmProvider, String>{};

  static Future<SettingsService> load() async {
    final s = SettingsService._(await SharedPreferences.getInstance(), SecretStore.create());
    s._migrateLegacy();
    for (final p in LlmProvider.values) {
      final stored = s._prefs.getString(_tokenKey(p));
      s._tokens[p] = stored == null ? '' : (s._secrets.decrypt(stored) ?? '');
    }
    return s;
  }

  /// Older builds stored one model and one token for whichever provider was selected.
  void _migrateLegacy() {
    final current = provider;
    final legacyModel = _prefs.getString(_kLegacyModel);
    if (legacyModel != null) {
      if (!_prefs.containsKey(_modelKey(current))) _prefs.setString(_modelKey(current), legacyModel);
      _prefs.remove(_kLegacyModel);
    }
    final legacyToken = _prefs.getString(_kLegacyToken);
    if (legacyToken != null) {
      if (!_prefs.containsKey(_tokenKey(current))) _prefs.setString(_tokenKey(current), legacyToken);
      _prefs.remove(_kLegacyToken);
    }
  }

  Locale get locale => Locale(_prefs.getString(_kLocale) ?? 'uz');
  // Stored id 'openai' (previously also used for "OpenAI-compatible") maps to LlmProvider.openAi.
  LlmProvider get provider => LlmProvider.fromId(_prefs.getString(_kProvider));
  String get baseUrl => _prefs.getString(_kBaseUrl) ?? defaultOpenAiBaseUrl;
  int get maxContext => _prefs.getInt(_kMaxContext) ?? 5;

  String modelFor(LlmProvider p) => _prefs.getString(_modelKey(p)) ?? defaultModelFor(p);
  String tokenFor(LlmProvider p) => _tokens[p] ?? '';

  /// Model and token of the currently selected provider.
  String get model => modelFor(provider);
  String get token => tokenFor(provider);
  bool get hasToken => token.isNotEmpty;
  bool get isAiConfigured => hasToken && model.trim().isNotEmpty;

  Future<void> setLocale(String code) async {
    await _prefs.setString(_kLocale, code);
    notifyListeners();
  }

  /// Saves the choices for every provider at once, plus which one is active.
  Future<void> saveAi({
    required LlmProvider provider,
    required Map<LlmProvider, String> models,
    required Map<LlmProvider, String> tokens,
    required String baseUrl,
    required int maxContext,
  }) async {
    await _prefs.setString(_kProvider, provider.id);
    await _prefs.setString(_kBaseUrl, baseUrl.trim());
    await _prefs.setInt(_kMaxContext, maxContext);
    for (final p in LlmProvider.values) {
      final model = (models[p] ?? '').trim();
      if (model.isEmpty) {
        await _prefs.remove(_modelKey(p));
      } else {
        await _prefs.setString(_modelKey(p), model);
      }
      final token = (tokens[p] ?? '').trim();
      _tokens[p] = token;
      if (token.isEmpty) {
        await _prefs.remove(_tokenKey(p));
      } else {
        await _prefs.setString(_tokenKey(p), _secrets.encrypt(token));
      }
    }
    notifyListeners();
  }
}
