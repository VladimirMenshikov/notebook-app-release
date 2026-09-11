import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/tasks/domain/task_model.dart';

final tasksLoadingProvider = StateProvider<bool>((ref) => false);
final tasksErrorProvider = StateProvider<String?>((ref) => null);
final tasksFilterProvider =
    StateProvider<TaskFilter>((ref) => TaskFilter.active);
final tasksSearchProvider = StateProvider<String>((ref) => '');

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier(ref);
});

class TasksNotifier extends StateNotifier<List<Task>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;

  TasksNotifier(this._ref) : super([]) {
    _ref.listen(tasksFilterProvider, (_, __) => loadTasks(refresh: true));
    _ref.listen(currentGroupProvider, (_, __) => loadTasks(refresh: true));
    _ref.listen(tasksSearchProvider, (_, __) {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => loadTasks(refresh: true),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  TaskFilter get currentFilter => _ref.read(tasksFilterProvider);

  Future<void> loadTasks({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = [];
      _hasMore = true;
    }

    _ref.read(tasksLoadingProvider.notifier).state = true;
    _ref.read(tasksErrorProvider.notifier).state = null;

    try {
      final apiClient = _ref.read(apiClientProvider);
      final group = _ref.read(currentGroupProvider);
      final search = _ref.read(tasksSearchProvider);

      bool? isCompleted;
      if (currentFilter == TaskFilter.active) isCompleted = false;
      if (currentFilter == TaskFilter.completed) isCompleted = true;

      final response = await apiClient.getTasks(
        page: _currentPage,
        limit: 50,
        isCompleted: isCompleted,
        groupId: group?.id,
        search: search,
      );

      final List<dynamic> tasksData = response['data'] ?? [];
      final List<Task> tasks = tasksData
          .map((json) => Task.fromJson(json as Map<String, dynamic>))
          .toList();

      state = refresh ? tasks : [...state, ...tasks];
      _hasMore = tasks.length >= 50;
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    } finally {
      _ref.read(tasksLoadingProvider.notifier).state = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _currentPage++;
    await loadTasks();
  }

  Future<void> createTask(Task task, {ItemVisibility? visibility}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final group = _ref.read(currentGroupProvider);
      final created = await apiClient.createTask({
        'title': task.title,
        'description': task.description,
        'priority': task.priority.name,
        if (task.dueDate != null) 'dueDate': task.dueDate!.toIso8601String(),
        if (group != null) 'groupId': group.id,
        if (group != null)
          'visibility': visibilityToString(visibility ?? ItemVisibility.personal),
      });
      state = [Task.fromJson(created), ...state];
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> updateTask(Task task, {ItemVisibility? visibility}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final updated = await apiClient.updateTask(task.id, {
        'title': task.title,
        'description': task.description,
        'isCompleted': task.isCompleted,
        'priority': task.priority.name,
        if (task.dueDate != null) 'dueDate': task.dueDate!.toIso8601String(),
        if (visibility != null) 'visibility': visibilityToString(visibility),
      });
      final result = Task.fromJson(updated);
      state = state.map((t) => t.id == task.id ? result : t).toList();
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.deleteTask(id);
      state = state.where((t) => t.id != id).toList();
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> toggleComplete(String id) async {
    // Задача верхнего уровня.
    final top = state.where((t) => t.id == id).toList();
    if (top.isNotEmpty) {
      final task = top.first;
      await _patchCompletion(task, !task.isCompleted);
      return;
    }
    // Подзадача.
    for (final parent in state) {
      final sub = parent.subtasks.where((s) => s.id == id).toList();
      if (sub.isNotEmpty) {
        await _patchCompletion(sub.first, !sub.first.isCompleted, parent: parent);
        return;
      }
    }
  }

  Future<void> _patchCompletion(Task task, bool value, {Task? parent}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.updateTask(task.id, {'isCompleted': value});
      if (parent == null) {
        state = state
            .map((t) => t.id == task.id ? t.copyWith(isCompleted: value) : t)
            .toList();
      } else {
        final newSubs = parent.subtasks
            .map((s) => s.id == task.id ? s.copyWith(isCompleted: value) : s)
            .toList();
        state = state
            .map((t) => t.id == parent.id ? t.copyWith(subtasks: newSubs) : t)
            .toList();
      }
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> addSubtask(String parentId, String title) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final created = await apiClient.createSubtask(parentId, {'title': title});
      final sub = Task.fromJson(created);
      state = state.map((t) {
        if (t.id != parentId) return t;
        return t.copyWith(subtasks: [...t.subtasks, sub]);
      }).toList();
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> updateSubtask(String parentId, String subtaskId, String title) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final updated = await apiClient.updateTask(subtaskId, {'title': title});
      final sub = Task.fromJson(updated);
      state = state.map((t) {
        if (t.id != parentId) return t;
        return t.copyWith(
          subtasks:
              t.subtasks.map((s) => s.id == subtaskId ? sub : s).toList(),
        );
      }).toList();
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> deleteSubtask(String parentId, String subtaskId) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.deleteTask(subtaskId);
      state = state.map((t) {
        if (t.id != parentId) return t;
        return t.copyWith(
          subtasks: t.subtasks.where((s) => s.id != subtaskId).toList(),
        );
      }).toList();
    } catch (e) {
      _ref.read(tasksErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }
}
