import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../l10n/app_localizations.dart';
import '../services/llm_catalog.dart';
import 'app_logo.dart';
import 'categories_page.dart';
import 'documents_page.dart';
import 'search_page.dart';
import 'settings_page.dart';
import 'theme.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    const pages = [CategoriesPage(), DocumentsPage(), SearchPage(), SettingsPage()];
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          return Row(
            children: [
              ValueListenableBuilder<int>(
                valueListenable: app.navIndex,
                builder: (context, index, _) => _Sidebar(
                  compact: compact,
                  index: index,
                  onSelect: (i) => app.navIndex.value = i,
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: app.navIndex,
                  builder: (context, index, _) => IndexedStack(index: index, children: pages),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.compact, required this.index, required this.onSelect});
  final bool compact;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final brand = context.brand;
    final items = [
      (Icons.folder_copy_outlined, Icons.folder_copy, l.navCategories),
      (Icons.description_outlined, Icons.description, l.navDocuments),
      (Icons.auto_awesome_outlined, Icons.auto_awesome, l.navSearch),
      (Icons.tune_outlined, Icons.tune, l.navSettings),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: compact ? 76 : 252,
      color: brand.sidebar,
      padding: EdgeInsets.fromLTRB(compact ? 12 : 16, 24, compact ? 12 : 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 0 : 6),
            child: Row(
              mainAxisAlignment: compact ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                const AppLogo(size: 40, glow: true),
                if (!compact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.appTitle, style: TextStyle(color: brand.sidebarText, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                        Text(l.appTagline, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: brand.sidebarMuted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          for (var i = 0; i < items.length; i++)
            _NavItem(
              icon: items[i].$1,
              selectedIcon: items[i].$2,
              label: items[i].$3,
              selected: index == i,
              compact: compact,
              onTap: () => onSelect(i),
            ),
          const Spacer(),
          _AiStatus(compact: compact, onTap: () => onSelect(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({required this.icon, required this.selectedIcon, required this.label, required this.selected, required this.compact, required this.onTap});
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final selected = widget.selected;
    final fg = selected ? Colors.white : brand.sidebarText.withValues(alpha: 0.78);
    final item = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 46,
          margin: const EdgeInsets.only(bottom: 4),
          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 0 : 14),
          decoration: BoxDecoration(
            color: selected ? brand.sidebarSelected : (_hover ? Colors.white.withValues(alpha: 0.06) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: widget.compact ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(selected ? widget.selectedIcon : widget.icon, size: 21, color: selected ? brand.marker : fg),
              if (!widget.compact) ...[
                const SizedBox(width: 14),
                Expanded(child: Text(widget.label, style: TextStyle(color: fg, fontSize: 14.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500))),
                if (selected) Container(width: 6, height: 6, decoration: BoxDecoration(color: brand.marker, shape: BoxShape.circle)),
              ],
            ],
          ),
        ),
      ),
    );
    return widget.compact ? Tooltip(message: widget.label, child: item) : item;
  }
}

/// Bottom-of-sidebar card: which AI is active, and whether it is ready.
class _AiStatus extends StatelessWidget {
  const _AiStatus({required this.compact, required this.onTap});
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final brand = context.brand;
    final app = AppScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([app.settings, app.indexer]),
      builder: (context, _) {
        final s = app.settings;
        final ready = s.isAiConfigured;
        final dot = ready ? brand.success : brand.warning;
        final provider = s.provider == LlmProvider.anthropic ? 'Anthropic' : 'OpenAI';
        final idx = app.indexer;

        if (compact) {
          return Tooltip(
            message: ready ? '$provider · ${s.model}' : l.aiSetupNeeded,
            child: GestureDetector(
              onTap: onTap,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(12)),
                  child: Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(color: dot, shape: BoxShape.circle))),
                ),
              ),
            ),
          );
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: dot, shape: BoxShape.circle, boxShadow: [BoxShadow(color: dot.withValues(alpha: 0.6), blurRadius: 6)])),
                    const SizedBox(width: 8),
                    Text(ready ? l.aiReady : l.aiSetupNeeded, style: TextStyle(color: brand.sidebarText, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 6),
                  Text(
                    ready ? '$provider · ${s.model}' : l.aiSetupHint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: brand.sidebarMuted, fontSize: 11.5, height: 1.35),
                  ),
                  if (idx.pending > 0 && idx.error == null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.6, color: Color(0xFFB9BCF5))),
                      const SizedBox(width: 8),
                      Expanded(child: Text(l.indexingShort(idx.pending), style: TextStyle(color: brand.sidebarMuted, fontSize: 11))),
                    ]),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
