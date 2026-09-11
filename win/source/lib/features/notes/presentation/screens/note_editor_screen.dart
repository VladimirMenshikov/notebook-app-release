import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:notebook_app/features/notes/presentation/providers/notes_providers.dart';
import 'package:notebook_app/features/notes/domain/note_model.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/core/widgets/app_scrollbar.dart';

class NoteEditorScreen extends ConsumerStatefulWidget {
  final String noteId;
  const NoteEditorScreen({super.key, required this.noteId});

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isFavorite = false;
  Note? _note;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final data = await apiClient.getNote(widget.noteId);
      final note = Note.fromJson(data);
      
      setState(() {
        _note = note;
        _titleController.text = note.title;
        _contentController.text = note.content;
        _isFavorite = note.isFavorite;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_note == null) return;

    setState(() => _isSaving = true);

    try {
      final updated = _note!.copyWith(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        isFavorite: _isFavorite,
        updatedAt: DateTime.now(),
      );

      await ref.read(notesProvider.notifier).updateNote(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Заметка сохранена'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(friendlyErrorMessage(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Auto-save on back
        if (_note != null &&
            (_note!.title != _titleController.text ||
                _note!.content != _contentController.text ||
                _note!.isFavorite != _isFavorite)) {
          await _saveNote();
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_note?.title ?? 'Редактирование'),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.star : Icons.star_border,
                color: _isFavorite ? Colors.amber : null,
              ),
              onPressed: () async {
                setState(() => _isFavorite = !_isFavorite);
                if (_note != null) {
                  await ref
                      .read(notesProvider.notifier)
                      .toggleFavorite(_note!.id);
                }
              },
            ),
            PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'delete':
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить заметку?'),
                        content: const Text('Это действие нельзя отменить'),
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
                    );
                    if (confirmed == true) {
                      await ref
                          .read(notesProvider.notifier)
                          .deleteNote(_note!.id);
                      if (context.mounted) {
                        context.pop();
                      }
                    }
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Удалить', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _note == null
            ? const Center(child: CircularProgressIndicator())
            : AppScrollbar(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        hintText: 'Заголовок',
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.headlineSmall,
                      maxLines: null,
                    ),
                    const Divider(height: 32),
                    
                    // Content
                    TextField(
                      controller: _contentController,
                      decoration: const InputDecoration(
                        hintText: 'Начните писать...',
                        border: InputBorder.none,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      maxLines: null,
                      minLines: 15,
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Meta info
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Создано',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm:ss')
                                  .format(_note!.createdAt),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Изменено',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd.MM.yyyy HH:mm:ss')
                                  .format(_note!.updatedAt),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Символов',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _contentController.text.length.toString(),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _isSaving ? null : _saveNote,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save),
          label: Text(_isSaving ? 'Сохранение...' : 'Сохранить'),
        ),
      ),
    );
  }
}
