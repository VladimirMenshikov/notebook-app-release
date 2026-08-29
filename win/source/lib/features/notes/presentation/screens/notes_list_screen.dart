import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notebook_app/core/widgets/search_field.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/groups/presentation/widgets/group_selector_title.dart';
import 'package:notebook_app/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_app/features/notes/domain/note_model.dart';

class NotesListScreen extends ConsumerStatefulWidget {
  const NotesListScreen({super.key});

  @override
  ConsumerState<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends ConsumerState<NotesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notesProvider.notifier).loadNotes(refresh: true);
    });
  }

  void _showNewNoteDialog() {
    showDialog(context: context, builder: (ctx) => const _NewNoteDialog());
  }

  void _showEditNoteDialog(Note note) {
    showDialog(context: context, builder: (ctx) => _EditNoteDialog(note: note));
  }

  Future<void> _refreshNotes() async {
    await ref.read(notesProvider.notifier).loadNotes(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final isLoading = ref.watch(notesLoadingProvider);
    final error = ref.watch(notesErrorProvider);
    final searching = ref.watch(notesSearchProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const GroupSelectorTitle(section: 'Заметки'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: isLoading ? null : _refreshNotes,
          ),
        ],
      ),
      body: Column(
        children: [
          SearchField(
            hintText: 'Поиск заметок...',
            initialValue: ref.read(notesSearchProvider),
            onChanged: (v) =>
                ref.read(notesSearchProvider.notifier).state = v,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshNotes,
              child: isLoading && notes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48),
                              const SizedBox(height: 16),
                              Text(error),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshNotes,
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : notes.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 120),
                                Icon(Icons.note_alt_outlined,
                                    size: 64,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    searching
                                        ? 'Ничего не найдено'
                                        : 'Нет заметок',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    searching
                                        ? 'Попробуйте другой запрос'
                                        : 'Нажмите + чтобы создать',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: notes.length,
                              itemBuilder: (context, index) =>
                                  _buildNoteCard(notes[index]),
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewNoteDialog,
        icon: const Icon(Icons.add),
        label: const Text('Новая заметка'),
      ),
    );
  }

  Widget _buildNoteCard(Note note) {
    final current = ref.read(currentGroupProvider);
    final canDelete = note.isMine || (current?.isAdmin ?? false);

    final card = Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: note.isFavorite
              ? Colors.amber.shade100
              : Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            note.isFavorite ? Icons.star : Icons.note_alt,
            color: note.isFavorite
                ? Colors.amber
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(note.title,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              note.content.isEmpty
                  ? 'Пустая заметка'
                  : note.content
                      .substring(0, note.content.length.clamp(0, 100)),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (note.isShared || (!note.isMine && note.authorName != null)) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  if (note.isShared)
                    const Chip(
                      avatar: Icon(Icons.group, size: 14),
                      label: Text('Общее', style: TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (!note.isMine && note.authorName != null)
                    Chip(
                      avatar: const Icon(Icons.person, size: 14),
                      label: Text(note.authorName!,
                          style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(note.updatedAt),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final notifier = ref.read(notesProvider.notifier);
            switch (value) {
              case 'edit':
                _showEditNoteDialog(note);
                break;
              case 'favorite':
                await notifier.toggleFavorite(note.id);
                break;
              case 'delete':
                await notifier.deleteNote(note.id);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            PopupMenuItem(
              value: 'favorite',
              child: Text(
                  note.isFavorite ? 'Убрать из избранного' : 'В избранное'),
            ),
            if (canDelete)
              const PopupMenuItem(
                value: 'delete',
                child:
                    Text('Удалить', style: TextStyle(color: Colors.red)),
              ),
          ],
        ),
        onTap: () => context.push('/note/${note.id}'),
      ),
    );

    if (!canDelete) return card;

    return Dismissible(
      key: Key(note.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.error,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Удалить заметку?'),
                content: Text('Вы уверены, что хотите удалить "${note.title}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Отмена'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Удалить'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        ref.read(notesProvider.notifier).deleteNote(note.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заметка удалена'),
            duration: Duration(seconds: 3),
          ),
        );
      },
      child: card,
    );
  }
}

class _NewNoteDialog extends ConsumerStatefulWidget {
  const _NewNoteDialog();

  @override
  ConsumerState<_NewNoteDialog> createState() => _NewNoteDialogState();
}

class _NewNoteDialogState extends ConsumerState<_NewNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  ItemVisibility _visibility = ItemVisibility.personal;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inGroup = ref.watch(currentGroupProvider) != null;

    return AlertDialog(
      title: const Text('Новая заметка'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Введите заголовок' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Содержание',
                  prefixIcon: Icon(Icons.article),
                ),
                maxLines: 5,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Введите содержание'
                    : null,
              ),
              if (inGroup) ...[
                const SizedBox(height: 16),
                _VisibilitySelector(
                  value: _visibility,
                  onChanged: (v) => setState(() => _visibility = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final note = Note(
              id: '',
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await ref
                .read(notesProvider.notifier)
                .createNote(note, visibility: _visibility);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _EditNoteDialog extends ConsumerStatefulWidget {
  final Note note;
  const _EditNoteDialog({required this.note});

  @override
  ConsumerState<_EditNoteDialog> createState() => _EditNoteDialogState();
}

class _EditNoteDialogState extends ConsumerState<_EditNoteDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late ItemVisibility _visibility;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _visibility = widget.note.visibility;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentGroupProvider);
    final canChangeVisibility = widget.note.groupId != null &&
        (widget.note.isMine || (current?.isAdmin ?? false));

    return AlertDialog(
      title: const Text('Редактировать заметку'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Заголовок',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Введите заголовок' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Содержание',
                  prefixIcon: Icon(Icons.article),
                ),
                maxLines: 8,
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Введите содержание'
                    : null,
              ),
              if (canChangeVisibility) ...[
                const SizedBox(height: 16),
                _VisibilitySelector(
                  value: _visibility,
                  onChanged: (v) => setState(() => _visibility = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final updated = widget.note.copyWith(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              updatedAt: DateTime.now(),
            );
            await ref.read(notesProvider.notifier).updateNote(
                  updated,
                  visibility: canChangeVisibility &&
                          _visibility != widget.note.visibility
                      ? _visibility
                      : null,
                );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  final ItemVisibility value;
  final ValueChanged<ItemVisibility> onChanged;
  const _VisibilitySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ItemVisibility>(
      segments: const [
        ButtonSegment(
          value: ItemVisibility.personal,
          label: Text('Личное'),
          icon: Icon(Icons.person),
        ),
        ButtonSegment(
          value: ItemVisibility.shared,
          label: Text('Общее'),
          icon: Icon(Icons.group),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
