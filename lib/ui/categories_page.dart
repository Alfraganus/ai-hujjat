import 'package:flutter/material.dart';

import '../app_controller.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import 'theme.dart';
import 'widgets.dart';

Future<bool> confirmDelete(BuildContext context, String name, {String? warning}) async {
  final l = AppLocalizations.of(context);
  final scheme = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      icon: Icon(Icons.delete_outline, color: scheme.error, size: 30),
      title: Text(l.confirmDelete(name), textAlign: TextAlign.center),
      content: warning == null ? null : Text(warning, textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: Colors.white),
          onPressed: () => Navigator.pop(c, true),
          child: Text(l.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Future<void> _edit(BuildContext context, {Category? existing}) async {
    final app = AppScope.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _CategoryDialog(existing: existing),
    );
    if (name == null) return;
    if (existing == null) {
      app.db.createCategory(name);
    } else {
      app.db.renameCategory(existing.id, name);
    }
    app.refresh(documentsChanged: true);
  }

  Future<void> _delete(BuildContext context, Category cat) async {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    if (await confirmDelete(context, cat.name, warning: l.categoryDeleteWarning)) {
      app.db.deleteCategory(cat.id);
      app.refresh(documentsChanged: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final cats = app.categories;
    final total = cats.fold<int>(0, (s, c) => s + c.docCount);

    return PageFrame(
      title: l.navCategories,
      subtitle: cats.isEmpty ? null : '${cats.length} • ${l.documentsCount(total)}',
      actions: [
        FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.add, size: 20), label: Text(l.newCategory)),
      ],
      child: cats.isEmpty
          ? Padding(
              padding: const EdgeInsets.only(top: 60),
              child: EmptyState(
                icon: Icons.folder_copy_outlined,
                title: l.noCategories,
                subtitle: l.categoriesEmptyHint,
                action: FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.add, size: 20), label: Text(l.newCategory)),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 320, mainAxisExtent: 118, crossAxisSpacing: 16, mainAxisSpacing: 16),
              itemCount: cats.length,
              itemBuilder: (context, i) => _CategoryCard(
                category: cats[i],
                onEdit: () => _edit(context, existing: cats[i]),
                onDelete: () => _delete(context, cats[i]),
                onOpen: () => app.navIndex.value = 1,
              ),
            ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onEdit, required this.onDelete, required this.onOpen});
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = categoryColors(context, category.id);
    return HoverCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Row(
        children: [
          IconBadge(icon: Icons.folder_rounded, tint: colors.tint, color: colors.strong, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                const SizedBox(height: 6),
                Pill(l.documentsCount(category.docCount), icon: Icons.description_outlined, color: colors.strong, background: colors.tint, dense: true),
              ],
            ),
          ),
          PopupMenuButton<String>(
            tooltip: '',
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) => v == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: ListTile(dense: true, leading: const Icon(Icons.edit_outlined), title: Text(l.edit), contentPadding: EdgeInsets.zero)),
              PopupMenuItem(value: 'delete', child: ListTile(dense: true, leading: Icon(Icons.delete_outline, color: theme.colorScheme.error), title: Text(l.delete, style: TextStyle(color: theme.colorScheme.error)), contentPadding: EdgeInsets.zero)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Owns its TextEditingController so it is disposed only after the dialog's
/// exit animation has finished (disposing it right after pop crashes).
class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.existing});
  final Category? existing;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ctrl = TextEditingController(text: widget.existing?.name);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) Navigator.pop(context, _ctrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.existing == null ? l.newCategory : l.editCategory),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _ctrl,
            autofocus: true,
            decoration: InputDecoration(labelText: l.name, prefixIcon: const Icon(Icons.folder_outlined)),
            validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
            onFieldSubmitted: (_) => _submit(),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _submit, child: Text(l.save)),
      ],
    );
  }
}
