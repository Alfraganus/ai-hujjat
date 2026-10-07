import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_controller.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../services/llm_service.dart';
import '../services/quote_matcher.dart';
import 'app_logo.dart';
import 'theme.dart';
import 'widgets.dart';

enum _Stage { idle, searching, answering }

/// Everything shown for one submitted question.
class _Result {
  _Result({required this.id, required this.query, required this.hits, required this.sentCount});
  final int id;
  final String query;
  final List<SearchHit> hits; // everything retrieved
  final int sentCount; // how many of [hits] were given to the AI
  AiAnswer? answer;
  String? error;
  bool aiNotConfigured = false;

  // Accordion state.
  bool sourcesOpen = false;
  final Set<int> openSources = {};
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  int? _categoryId; // null = all categories

  int _seq = 0; // lets a newer question supersede one still in flight
  _Stage _stage = _Stage.idle;
  _Result? _result;

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ask() async {
    final query = _query.text.trim();
    if (query.isEmpty || _stage != _Stage.idle) return;
    final app = AppScope.of(context);
    final id = ++_seq;
    setState(() {
      _stage = _Stage.searching;
      _result = null;
    });

    final hits = await app.searchService.search(query, categoryId: _categoryId);
    if (!mounted || id != _seq) return;

    final sent = hits.length < app.settings.maxContext ? hits.length : app.settings.maxContext;
    final result = _Result(id: id, query: query, hits: hits, sentCount: sent);

    // Without an AI answer the passages are all there is, so show them open.
    void showPassagesOnly() {
      result
        ..sourcesOpen = true
        ..openSources.addAll(List.generate(hits.length, (i) => i));
    }

    if (hits.isEmpty) {
      // Nothing to ground an answer on: don't spend tokens.
      setState(() {
        _result = result;
        _stage = _Stage.idle;
      });
      return;
    }
    if (!app.settings.isAiConfigured) {
      result.aiNotConfigured = true;
      showPassagesOnly();
      setState(() {
        _result = result;
        _stage = _Stage.idle;
      });
      return;
    }

    setState(() {
      _result = result;
      _stage = _Stage.answering;
    });
    try {
      result.answer = await app.llm.answer(query, hits.take(sent).toList());
      result.openSources.addAll(result.answer!.sources.map((s) => s.index));
    } catch (e) {
      result.error = e.toString();
      showPassagesOnly();
    }
    if (!mounted || id != _seq) return;
    setState(() => _stage = _Stage.idle);
  }

  /// Opens the sources section and expands one passage (from an answer citation).
  void _openSource(_Result r, int index) {
    setState(() {
      r.sourcesOpen = true;
      r.openSources.add(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final cats = app.categories;

    // Drop the filter if its category was deleted.
    if (_categoryId != null && !cats.any((c) => c.id == _categoryId)) _categoryId = null;

    final result = _result;
    final showHero = result == null && _stage == _Stage.idle;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 920),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(36, 32, 36, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!showHero) ...[
                Text(l.navSearch, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
              ],
              _SearchBox(controller: _query, focus: _focus, busy: _stage != _Stage.idle, onSubmit: _ask),
              const SizedBox(height: 14),
              _CategoryFilter(
                categories: cats,
                selected: _categoryId,
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const _IndexError(),
              const SizedBox(height: 12),
              Expanded(
                child: showHero
                    ? _Hero(hasCategories: cats.isNotEmpty)
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 40),
                        children: [
                          if (_stage == _Stage.searching) _Progress(text: l.searching),
                          if (_stage == _Stage.answering) _Progress(text: l.aiThinking),
                          if (result != null) ..._resultWidgets(context, result),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _resultWidgets(BuildContext context, _Result r) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brand;
    if (r.hits.isEmpty) {
      return [Padding(padding: const EdgeInsets.only(top: 24), child: EmptyState(icon: Icons.search_off_rounded, title: l.noResults, subtitle: l.noResultsHint))];
    }
    return [
      if (r.aiNotConfigured)
        _Notice(
          icon: Icons.key_outlined,
          background: brand.warning.withValues(alpha: 0.14),
          foreground: scheme.onSurface,
          iconColor: brand.warning,
          text: l.aiNotConfigured,
          actionLabel: l.navSettings,
          onAction: () => app.navIndex.value = 3,
        ),
      if (r.error != null)
        _Notice(
          icon: Icons.error_outline,
          background: scheme.error.withValues(alpha: 0.10),
          foreground: scheme.onSurface,
          iconColor: scheme.error,
          text: l.aiError(r.error!),
          actionLabel: l.navSettings,
          onAction: () => app.navIndex.value = 3,
          selectable: true,
        ),
      if (r.answer != null) _AnswerCard(answer: r.answer!, citableCount: r.sentCount, onCite: (i) => _openSource(r, i)),
      _SourcesSection(
        result: r,
        onToggleSection: () => setState(() => r.sourcesOpen = !r.sourcesOpen),
        onToggleSource: (i) => setState(() => r.openSources.contains(i) ? r.openSources.remove(i) : r.openSources.add(i)),
      ),
    ];
  }
}

// ---------------------------------------------------------------- search box

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.focus, required this.busy, required this.onSubmit});
  final TextEditingController controller;
  final FocusNode focus;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final brand = context.brand;
    return ListenableBuilder(
      listenable: focus,
      builder: (context, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 62,
        padding: const EdgeInsets.fromLTRB(18, 0, 8, 0),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: focus.hasFocus ? scheme.primary : scheme.outlineVariant, width: focus.hasFocus ? 1.8 : 1),
          boxShadow: [BoxShadow(color: brand.gradientStart.withValues(alpha: focus.hasFocus ? 0.20 : 0.08), blurRadius: focus.hasFocus ? 28 : 18, offset: const Offset(0, 8))],
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, color: scheme.onSurfaceVariant, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focus,
                autofocus: true,
                textInputAction: TextInputAction.search,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  hintText: l.searchHint,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            ListenableBuilder(
              listenable: controller,
              builder: (_, _) => controller.text.isEmpty
                  ? const SizedBox.shrink()
                  : IconButton(tooltip: l.clear, icon: const Icon(Icons.close_rounded, size: 20), onPressed: controller.clear),
            ),
            const SizedBox(width: 4),
            _GradientButton(
              onTap: busy ? null : onSubmit,
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(l.navSearch, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14.5)),
                    ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    return Opacity(
      opacity: onTap == null ? 0.75 : 1,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(gradient: brand.gradient, borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(height: 46, padding: const EdgeInsets.symmetric(horizontal: 20), alignment: Alignment.center, child: child),
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends StatelessWidget {
  const _CategoryFilter({required this.categories, required this.selected, required this.onChanged});
  final List<Category> categories;
  final int? selected;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (categories.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Text(l.searchInCategory, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ),
        FilterPill(label: l.allCategories, selected: selected == null, onTap: () => onChanged(null)),
        for (final c in categories)
          FilterPill(label: c.name, dot: categoryColors(context, c.id).strong, selected: selected == c.id, onTap: () => onChanged(c.id)),
      ],
    );
  }
}

class _IndexError extends StatelessWidget {
  const _IndexError();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final idx = AppScope.of(context).indexer;
    return ListenableBuilder(
      listenable: idx,
      builder: (context, _) {
        if (idx.error == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(children: [
            Icon(Icons.info_outline, size: 16, color: context.brand.warning),
            const SizedBox(width: 8),
            Flexible(child: Text(l.semanticUnavailable, style: Theme.of(context).textTheme.bodySmall)),
          ]),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- empty hero

class _Hero extends StatelessWidget {
  const _Hero({required this.hasCategories});
  final bool hasCategories;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final app = AppScope.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 84, glow: true),
            const SizedBox(height: 28),
            Text(l.searchHeroTitle, textAlign: TextAlign.center, style: theme.textTheme.headlineMedium),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(l.searchPrompt, textAlign: TextAlign.center, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ),
            if (!hasCategories) ...[
              const SizedBox(height: 22),
              OutlinedButton.icon(
                onPressed: () => app.navIndex.value = 0,
                icon: const Icon(Icons.folder_copy_outlined, size: 20),
                label: Text(l.selectCategoryFirst),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- progress / notices

class _Progress extends StatelessWidget {
  const _Progress({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.auto_awesome, size: 18, color: scheme.primary),
                const SizedBox(width: 10),
                Text(text, style: Theme.of(context).textTheme.titleSmall),
              ]),
              const SizedBox(height: 14),
              ClipRRect(borderRadius: BorderRadius.circular(99), child: const LinearProgressIndicator(minHeight: 5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.iconColor,
    required this.text,
    required this.actionLabel,
    required this.onAction,
    this.selectable = false,
  });
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color iconColor;
  final String text;
  final String actionLabel;
  final VoidCallback onAction;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: foreground, height: 1.45);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(16), border: Border.all(color: iconColor.withValues(alpha: 0.35))),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Padding(padding: const EdgeInsets.only(top: 1), child: selectable ? SelectableText(text, style: style) : Text(text, style: style))),
            TextButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- answer

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer, required this.citableCount, required this.onCite});
  final AiAnswer answer;
  final int citableCount;
  final ValueChanged<int> onCite;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.brand;
    final tokens = '${answer.inputTokens} in · ${answer.outputTokens} out';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [BoxShadow(color: brand.gradientStart.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, decoration: BoxDecoration(gradient: brand.gradient)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(gradient: brand.gradient, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.auto_awesome, size: 17, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(l.aiAnswer, style: theme.textTheme.titleMedium)),
                        IconButton(
                          tooltip: l.copy,
                          icon: const Icon(Icons.copy_rounded, size: 19),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: answer.text));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.copied), duration: const Duration(seconds: 1)));
                          },
                        ),
                      ]),
                      const SizedBox(height: 12),
                      _AnswerText(text: answer.text, citableCount: citableCount, onCite: onCite),
                      const SizedBox(height: 14),
                      Wrap(spacing: 8, runSpacing: 6, children: [
                        Pill(tokens, icon: Icons.token_outlined, dense: true),
                        if (answer.costUsd != null) Pill('≈ \$${answer.costUsd!.toStringAsFixed(4)}', icon: Icons.payments_outlined, dense: true),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Answer text where inline [n] citations become tappable badges.
class _AnswerText extends StatefulWidget {
  const _AnswerText({required this.text, required this.citableCount, required this.onCite});
  final String text;
  final int citableCount;
  final ValueChanged<int> onCite;

  @override
  State<_AnswerText> createState() => _AnswerTextState();
}

class _AnswerTextState extends State<_AnswerText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final theme = Theme.of(context);
    final base = theme.textTheme.bodyLarge!.copyWith(fontSize: 15.5, height: 1.65);
    final spans = <InlineSpan>[];
    var pos = 0;
    for (final m in RegExp(r'\[(\d{1,2})\]').allMatches(widget.text)) {
      final n = int.parse(m.group(1)!);
      if (n < 1 || n > widget.citableCount) continue;
      if (m.start > pos) spans.add(TextSpan(text: widget.text.substring(pos, m.start)));
      final recognizer = TapGestureRecognizer()..onTap = () => widget.onCite(n - 1);
      _recognizers.add(recognizer);
      spans.add(TextSpan(
        text: ' $n ',
        recognizer: recognizer,
        mouseCursor: SystemMouseCursors.click,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onPrimaryContainer,
          backgroundColor: theme.colorScheme.primaryContainer,
        ),
      ));
      pos = m.end;
    }
    if (pos < widget.text.length) spans.add(TextSpan(text: widget.text.substring(pos)));
    return SelectionArea(child: Text.rich(TextSpan(style: base, children: spans)));
  }
}

// ---------------------------------------------------------------- sources

class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.result, required this.onToggleSection, required this.onToggleSource});
  final _Result result;
  final VoidCallback onToggleSection;
  final ValueChanged<int> onToggleSource;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final cited = {for (final s in result.answer?.sources ?? const <CitedSource>[]) s.index: s};
    final order = [
      ...cited.keys.where((i) => i < result.hits.length),
      for (var i = 0; i < result.hits.length; i++)
        if (!cited.containsKey(i)) i,
    ];
    final terms = highlightWords(result.query);
    final open = result.sourcesOpen;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggleSection,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(children: [
                Icon(Icons.menu_book_outlined, color: scheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text(l.sourcesCount(result.hits.length), style: theme.textTheme.titleMedium)),
                if (cited.isNotEmpty) Padding(padding: const EdgeInsets.only(right: 10), child: Pill(l.usedByAiCount(cited.length), dense: true, color: scheme.primary, background: scheme.primaryContainer)),
                AnimatedRotation(turns: open ? 0.5 : 0, duration: const Duration(milliseconds: 180), child: Icon(Icons.expand_more_rounded, color: scheme.onSurfaceVariant)),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: [
                        for (final i in order)
                          _SourceTile(
                            number: i + 1,
                            hit: result.hits[i],
                            citedSource: cited[i],
                            terms: terms,
                            expanded: result.openSources.contains(i),
                            onToggle: () => onToggleSource(i),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.number, required this.hit, required this.citedSource, required this.terms, required this.expanded, required this.onToggle});
  final int number;
  final SearchHit hit;
  final CitedSource? citedSource;
  final List<String> terms;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final brand = context.brand;
    final isCited = citedSource != null;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isCited ? scheme.primaryContainer.withValues(alpha: 0.35) : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isCited ? scheme.primary.withValues(alpha: 0.35) : scheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(children: [
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: isCited ? brand.gradient : null,
                    color: isCited ? null : scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('$number', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: isCited ? Colors.white : scheme.onSurfaceVariant)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(hit.documentTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall)),
                if (isCited) Padding(padding: const EdgeInsets.only(right: 8), child: Pill(l.usedByAi, icon: Icons.check_circle_outline, dense: true, color: brand.onMarker, background: brand.marker)),
                AnimatedRotation(turns: expanded ? 0.5 : 0, duration: const Duration(milliseconds: 180), child: Icon(Icons.expand_more_rounded, size: 22, color: scheme.onSurfaceVariant)),
              ]),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: SelectableText.rich(highlightedText(hit.text, citedSource?.quotes ?? const [], terms, context)),
            ),
        ],
      ),
    );
  }
}

/// Words of the query for highlighting. Unlike the search index (which splits
/// at apostrophes) this keeps them, so "to'lanadi" is marked as one word.
List<String> highlightWords(String query) => RegExp(r"[\p{L}\p{N}'’ʻʼ]+", unicode: true)
    .allMatches(query)
    .map((m) => m.group(0)!.replaceAll(RegExp(r"^['’ʻʼ]+|['’ʻʼ]+$"), ''))
    .where((w) => w.isNotEmpty)
    .toList();

/// Highlights the AI's quoted passages like a marker pen; if none can be
/// located (or the AI gave none), falls back to marking the search words.
TextSpan highlightedText(String text, List<String> quotes, List<String> terms, BuildContext context) {
  final theme = Theme.of(context);
  final brand = context.brand;
  final base = TextStyle(fontSize: 14.5, height: 1.65, color: theme.colorScheme.onSurface);
  final quoteRanges = findQuoteRanges(text, quotes);
  if (quoteRanges.isNotEmpty) {
    return _spans(
      text,
      quoteRanges.map((r) => (r.start, r.end)).toList(),
      base,
      TextStyle(backgroundColor: brand.marker, color: brand.onMarker, fontWeight: FontWeight.w600),
    );
  }
  if (terms.isEmpty) return TextSpan(text: text, style: base);
  // Mark the whole word that starts with a query word (prefix search semantics).
  final alternatives = terms.map(RegExp.escape).join('|');
  final re = RegExp('(?:$alternatives)' r"[\p{L}\p{N}'’ʻʼ]*", caseSensitive: false, unicode: true);
  return _spans(
    text,
    [for (final m in re.allMatches(text)) (m.start, m.end)],
    base,
    TextStyle(backgroundColor: theme.colorScheme.primaryContainer, color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
  );
}

TextSpan _spans(String text, List<(int, int)> ranges, TextStyle base, TextStyle mark) {
  final spans = <TextSpan>[];
  var pos = 0;
  for (final (start, end) in ranges) {
    if (start > pos) spans.add(TextSpan(text: text.substring(pos, start)));
    spans.add(TextSpan(text: text.substring(start, end), style: mark));
    pos = end;
  }
  if (pos < text.length) spans.add(TextSpan(text: text.substring(pos)));
  return TextSpan(style: base, children: spans);
}
