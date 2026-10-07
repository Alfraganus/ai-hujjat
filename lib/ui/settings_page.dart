import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/llm_catalog.dart';
import 'theme.dart';
import 'widgets.dart';

const _customModelValue = '__custom__';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late LlmProvider _provider;
  // Per-provider drafts; the text fields below show the active provider's.
  final _choice = <LlmProvider, String>{}; // catalog id or _customModelValue
  final _customText = <LlmProvider, String>{};
  final _tokens = <LlmProvider, String>{};

  late final TextEditingController _customModel;
  late final TextEditingController _baseUrl;
  late final TextEditingController _token;
  late double _maxContext;
  bool _showToken = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final s = AppScope.of(context).settings;
    _provider = s.provider;
    for (final p in LlmProvider.values) {
      final model = s.modelFor(p);
      if (findModel(p, model) != null) {
        _choice[p] = model;
        _customText[p] = '';
      } else {
        _choice[p] = _customModelValue;
        _customText[p] = model;
      }
      _tokens[p] = s.tokenFor(p);
    }
    _customModel = TextEditingController(text: _customText[_provider]);
    _token = TextEditingController(text: _tokens[_provider]);
    _baseUrl = TextEditingController(text: s.baseUrl);
    _maxContext = s.maxContext.toDouble();
  }

  @override
  void dispose() {
    _customModel.dispose();
    _baseUrl.dispose();
    _token.dispose();
    super.dispose();
  }

  void _stash() {
    _customText[_provider] = _customModel.text;
    _tokens[_provider] = _token.text;
  }

  void _switchProvider(LlmProvider next) {
    if (next == _provider) return;
    _stash();
    setState(() {
      _provider = next;
      _customModel.text = _customText[next] ?? '';
      _token.text = _tokens[next] ?? '';
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final settings = AppScope.of(context).settings;
    _stash();
    final models = {
      for (final p in LlmProvider.values)
        p: _choice[p] == _customModelValue ? (_customText[p] ?? '') : _choice[p]!,
    };
    await settings.saveAi(
      provider: _provider,
      models: models,
      tokens: Map.of(_tokens),
      baseUrl: _baseUrl.text,
      maxContext: _maxContext.round(),
    );
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.settingsSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = AppScope.of(context).settings;
    final isOpenAi = _provider == LlmProvider.openAi;
    final models = modelsFor(_provider);
    final defaultId = defaultModelFor(_provider);
    final showCustom = _choice[_provider] == _customModelValue;
    final savedToken = settings.tokenFor(_provider).isNotEmpty;

    return PageFrame(
      title: l.navSettings,
      maxWidth: 820,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Section(
            icon: Icons.translate_rounded,
            title: l.settingsLanguage,
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 'uz', label: Text("O'zbekcha")),
                ButtonSegment(value: 'ru', label: Text('Русский')),
                ButtonSegment(value: 'en', label: Text('English')),
              ],
              selected: {settings.locale.languageCode},
              onSelectionChanged: (s) => settings.setLocale(s.first),
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            icon: Icons.auto_awesome_rounded,
            title: l.settingsAi,
            description: l.settingsOfflineNote,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(l.settingsProvider),
                Row(children: [
                  Expanded(
                    child: _ProviderTile(
                      letter: 'A',
                      name: l.providerAnthropic,
                      ready: settings.tokenFor(LlmProvider.anthropic).isNotEmpty,
                      selected: _provider == LlmProvider.anthropic,
                      onTap: () => _switchProvider(LlmProvider.anthropic),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProviderTile(
                      letter: 'O',
                      name: l.providerOpenAi,
                      ready: settings.tokenFor(LlmProvider.openAi).isNotEmpty,
                      selected: _provider == LlmProvider.openAi,
                      onTap: () => _switchProvider(LlmProvider.openAi),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: _Label(l.settingsModel)),
                  Text(l.settingsPriceHint, style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                ]),
                Container(
                  decoration: BoxDecoration(border: Border.all(color: scheme.outlineVariant), borderRadius: BorderRadius.circular(14)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      for (var i = 0; i < models.length; i++) ...[
                        if (i > 0) const Divider(),
                        _ModelRow(
                          id: models[i].id,
                          price: models[i].priceLabel,
                          selected: _choice[_provider] == models[i].id,
                          badges: [
                            if (i == 0) (text: l.settingsCheapest, highlight: true),
                            if (models[i].id == defaultId) (text: l.settingsDefault, highlight: false),
                          ],
                          onTap: () => setState(() => _choice[_provider] = models[i].id),
                        ),
                      ],
                      const Divider(),
                      _ModelRow(
                        id: l.customModel,
                        selected: showCustom,
                        onTap: () => setState(() => _choice[_provider] = _customModelValue),
                      ),
                    ],
                  ),
                ),
                if (showCustom) ...[
                  const SizedBox(height: 12),
                  TextField(controller: _customModel, decoration: InputDecoration(labelText: l.settingsCustomModel)),
                ],
                if (isOpenAi) ...[
                  const SizedBox(height: 20),
                  TextField(
                    controller: _baseUrl,
                    decoration: InputDecoration(labelText: l.settingsBaseUrl, helperText: l.settingsBaseUrlHint, prefixIcon: const Icon(Icons.link_rounded)),
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _token,
                  obscureText: !_showToken,
                  enableSuggestions: false,
                  autocorrect: false,
                  decoration: InputDecoration(
                    labelText: l.settingsToken,
                    helperText: savedToken ? '${l.settingsTokenSet} • ${l.settingsTokenHint}' : l.settingsTokenMissing,
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      tooltip: l.settingsShowToken,
                      icon: Icon(_showToken ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _showToken = !_showToken),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(child: _Label(l.settingsMaxContext)),
                  Pill('${_maxContext.round()}', color: scheme.primary, background: scheme.primaryContainer),
                ]),
                Slider(
                  value: _maxContext,
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _maxContext.round().toString(),
                  onChanged: (v) => setState(() => _maxContext = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(onPressed: _save, icon: const Icon(Icons.check_rounded, size: 20), label: Text(l.save)),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.icon, required this.title, this.description, required this.child});
  final IconData icon;
  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brand = context.brand;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(gradient: brand.gradient, borderRadius: BorderRadius.circular(11)),
                child: Icon(icon, size: 19, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Text(title, style: theme.textTheme.titleLarge),
            ]),
            if (description != null) ...[
              const SizedBox(height: 10),
              Text(description!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _ProviderTile extends StatelessWidget {
  const _ProviderTile({required this.letter, required this.name, required this.ready, required this.selected, required this.onTap});
  final String letter;
  final String name;
  final bool ready;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.brand;
    return HoverCard(
      selected: selected,
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? brand.gradient : null,
            color: selected ? null : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(letter, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: selected ? Colors.white : scheme.onSurfaceVariant)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Row(children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: ready ? brand.success : brand.warning, shape: BoxShape.circle)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    ready ? AppLocalizations.of(context).settingsTokenSet : AppLocalizations.of(context).settingsTokenMissing,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ),
              ]),
            ],
          ),
        ),
        if (selected) Icon(Icons.check_circle_rounded, color: scheme.primary),
      ]),
    );
  }
}

class _ModelRow extends StatelessWidget {
  const _ModelRow({required this.id, this.price, required this.selected, required this.onTap, this.badges = const []});
  final String id;
  final String? price;
  final bool selected;
  final VoidCallback onTap;
  final List<({String text, bool highlight})> badges;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.brand;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected ? scheme.primaryContainer.withValues(alpha: 0.45) : null,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded, size: 21, color: selected ? scheme.primary : scheme.outline),
          const SizedBox(width: 14),
          Expanded(
            child: Row(children: [
              Flexible(
                child: Text(id, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500, fontSize: 14.5, color: scheme.onSurface)),
              ),
              for (final b in badges) ...[
                const SizedBox(width: 8),
                Pill(
                  b.text,
                  dense: true,
                  color: b.highlight ? brand.onMarker : scheme.primary,
                  background: b.highlight ? brand.marker : scheme.primaryContainer,
                ),
              ],
            ]),
          ),
          if (price != null) Text(price!, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant, fontFeatures: const [FontFeature.tabularFigures()])),
        ]),
      ),
    );
  }
}
