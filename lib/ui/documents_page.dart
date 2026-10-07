import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_controller.dart';
import '../data/models.dart';
import '../l10n/app_localizations.dart';
import '../services/text_extractor.dart';
import 'categories_page.dart' show confirmDelete;
import 'theme.dart';
import 'widgets.dart';

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  int? _categoryId; // null = all

  Future<void> _edit(BuildContext context, {Document? existing}) async {
    final app = AppScope.of(context);
    if (app.categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).selectCategoryFirst)));
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (c) => _DocumentDialog(existing: existing, initialCategoryId: _categoryId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final app = AppScope.of(context);
    final cats = app.categories;
    // Drop a stale filter if its category was deleted.
    if (_categoryId != null && !cats.any((c) => c.id == _categoryId)) _categoryId = null;
    final docs = app.db.documents(categoryId: _categoryId);
    final byId = {for (final c in cats) c.id: c};
    final total = cats.fold<int>(0, (s, c) => s + c.docCount);

    return PageFrame(
      title: l.navDocuments,
      subtitle: l.documentsCount(docs.length),
      actions: [
        FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.add, size: 20), label: Text(l.addDocument)),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cats.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterPill(label: l.allCategories, count: total, selected: _categoryId == null, onTap: () => setState(() => _categoryId = null)),
                for (final c in cats)
                  FilterPill(
                    label: c.name,
                    count: c.docCount,
                    dot: categoryColors(context, c.id).strong,
                    selected: _categoryId == c.id,
                    onTap: () => setState(() => _categoryId = c.id),
                  ),
              ],
            ),
          const SizedBox(height: 20),
          if (docs.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: EmptyState(
                icon: Icons.description_outlined,
                title: cats.isEmpty ? l.selectCategoryFirst : l.noDocuments,
                subtitle: cats.isEmpty ? null : l.documentsEmptyHint,
                action: cats.isEmpty
                    ? FilledButton.icon(onPressed: () => app.navIndex.value = 0, icon: const Icon(Icons.folder_copy_outlined, size: 20), label: Text(l.navCategories))
                    : FilledButton.icon(onPressed: () => _edit(context), icon: const Icon(Icons.add, size: 20), label: Text(l.addDocument)),
              ),
            )
          else
            for (final d in docs)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DocumentRow(
                  document: d,
                  category: byId[d.categoryId],
                  onOpen: () => _edit(context, existing: d),
                  onDelete: () async {
                    if (await confirmDelete(context, d.title)) {
                      app.db.deleteDocument(d.id);
                      app.refresh(documentsChanged: true);
                    }
                  },
                ),
              ),
        ],
      ),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.document, required this.category, required this.onOpen, required this.onDelete});
  final Document document;
  final Category? category;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = categoryColors(context, document.categoryId);
    final date = DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(document.updatedAt);
    final snippet = document.content.replaceAll(RegExp(r'\s+'), ' ').trim();

    return HoverCard(
      onTap: onOpen,
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          IconBadge(icon: Icons.description_rounded, tint: colors.tint, color: colors.strong),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(document.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(snippet, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (category != null) ConstrainedBox(constraints: const BoxConstraints(maxWidth: 160), child: Pill(category!.name, color: colors.strong, background: colors.tint, dense: true)),
              const SizedBox(height: 6),
              Text(date, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          PopupMenuButton<String>(
            tooltip: '',
            icon: Icon(Icons.more_vert, color: theme.colorScheme.onSurfaceVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (v) => v == 'edit' ? onOpen() : onDelete(),
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

class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog({this.existing, this.initialCategoryId});
  final Document? existing;
  final int? initialCategoryId;

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title = TextEditingController(text: widget.existing?.title);
  late final TextEditingController _content = TextEditingController(text: widget.existing?.content);
  int? _categoryId;
  bool _importing = false;
  String? _importError;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.existing?.categoryId ?? widget.initialCategoryId;
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final l = AppLocalizations.of(context);
    final res = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: supportedImportExtensions);
    final path = res.isEmpty ? null : res.first.path;
    if (path == null) return;
    setState(() {
      _importing = true;
      _importError = null;
    });
    try {
      final text = await extractText(path);
      if (!mounted) return;
      if (text.trim().isEmpty) {
        setState(() => _importError = l.importEmpty);
        return;
      }
      setState(() {
        _content.text = text;
        if (_title.text.trim().isEmpty) {
          _title.text = path.split(RegExp(r'[\\/]')).last.replaceFirst(RegExp(r'\.[^.]+$'), '');
        }
      });
    } catch (e) {
      if (mounted) setState(() => _importError = l.importFailed(e.toString()));
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final app = AppScope.of(context);
    app.db.saveDocument(
      id: widget.existing?.id,
      categoryId: _categoryId!,
      title: _title.text,
      content: _content.text,
    );
    app.refresh(documentsChanged: true);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final app = AppScope.of(context);
    final cats = app.categories;
    _categoryId ??= cats.first.id;
    return AlertDialog(
      title: Text(widget.existing == null ? l.addDocument : l.editDocument),
      content: SizedBox(
        width: 680,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 220,
                      child: DropdownButtonFormField<int>(
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: InputDecoration(labelText: l.category),
                        items: [
                          for (final c in cats)
                            DropdownMenuItem(
                              value: c.id,
                              child: Row(children: [
                                Container(width: 9, height: 9, decoration: BoxDecoration(color: categoryColors(context, c.id).strong, shape: BoxShape.circle)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(c.name, overflow: TextOverflow.ellipsis)),
                              ]),
                            ),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _title,
                        decoration: InputDecoration(labelText: l.title),
                        validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _content,
                  minLines: 9,
                  maxLines: 14,
                  decoration: InputDecoration(labelText: l.content, alignLabelWithHint: true),
                  validator: (v) => (v == null || v.trim().isEmpty) ? l.required : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _importing ? null : _import,
                  icon: _importing
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload_file_outlined, size: 20),
                  label: Text(l.importFile),
                ),
                if (_importError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_importError!, style: TextStyle(color: theme.colorScheme.error)),
                  ),
              ],
            ),
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(onPressed: _save, child: Text(l.save)),
      ],
    );
  }
}
