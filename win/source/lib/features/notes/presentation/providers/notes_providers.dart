import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/notes/domain/note_model.dart';

// State
final notesLoadingProvider = StateProvider<bool>((ref) => false);
final notesErrorProvider = StateProvider<String?>((ref) => null);
final notesSearchProvider = StateProvider<String>((ref) => '');

final notesProvider = StateNotifierProvider<NotesNotifier, List<Note>>((ref) {
  return NotesNotifier(ref);
});

class NotesNotifier extends StateNotifier<List<Note>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;

  NotesNotifier(this._ref) : super([]) {
    _ref.listen(currentGroupProvider, (_, __) => loadNotes(refresh: true));
    _ref.listen(notesSearchProvider, (_, __) {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => loadNotes(refresh: true),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadNotes({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = [];
      _hasMore = true;
    }

    _ref.read(notesLoadingProvider.notifier).state = true;
    _ref.read(notesErrorProvider.notifier).state = null;

    try {
      final apiClient = _ref.read(apiClientProvider);
      final group = _ref.read(currentGroupProvider);
      final search = _ref.read(notesSearchProvider);

      final response = await apiClient.getNotes(
        page: _currentPage,
        limit: 50,
        groupId: group?.id,
        search: search,
      );

      final List<dynamic> notesData = response['data'] ?? [];
      final List<Note> notes = notesData
          .map((json) => Note.fromJson(json as Map<String, dynamic>))
          .toList();

      state = refresh ? notes : [...state, ...notes];
      _hasMore = notes.length >= 50;
    } catch (e) {
      _ref.read(notesErrorProvider.notifier).state = friendlyErrorMessage(e);
    } finally {
      _ref.read(notesLoadingProvider.notifier).state = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _currentPage++;
    await loadNotes();
  }

  Future<void> createNote(
    Note note, {
    ItemVisibility visibility = ItemVisibility.personal,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final group = _ref.read(currentGroupProvider);
      final created = await apiClient.createNote({
        'title': note.title,
        'content': note.content,
        if (group != null) 'groupId': group.id,
        if (group != null) 'visibility': visibilityToString(visibility),
      });
      state = [Note.fromJson(created), ...state];
    } catch (e) {
      _ref.read(notesErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> updateNote(Note note, {ItemVisibility? visibility}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final updated = await apiClient.updateNote(note.id, {
        'title': note.title,
        'content': note.content,
        'isFavorite': note.isFavorite,
        if (visibility != null) 'visibility': visibilityToString(visibility),
      });
      final result = Note.fromJson(updated);
      state = state.map((n) => n.id == note.id ? result : n).toList();
    } catch (e) {
      _ref.read(notesErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> deleteNote(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.deleteNote(id);
      state = state.where((n) => n.id != id).toList();
    } catch (e) {
      _ref.read(notesErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> toggleFavorite(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final result = await apiClient.toggleNoteFavorite(id);
      final updatedNote = Note.fromJson(result);
      state = state.map((n) => n.id == id ? updatedNote : n).toList();
    } catch (e) {
      _ref.read(notesErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }
}
