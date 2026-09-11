import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notebook_app/core/widgets/app_scrollbar.dart';
import 'package:notebook_app/core/widgets/search_field.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/groups/presentation/widgets/group_selector_title.dart';
import 'package:notebook_app/features/tasks/presentation/providers/tasks_providers.dart';
import 'package:notebook_app/features/tasks/domain/task_model.dart';

class TasksListScreen extends ConsumerStatefulWidget {
  const TasksListScreen({super.key});

  @override
  ConsumerState<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends ConsumerState<TasksListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks(refresh: true);
    });
  }

  Future<void> _refreshTasks() async {
    await ref.read(tasksProvider.notifier).loadTasks(refresh: true);
  }

  void _showNewTaskDialog() {
    showDialog(context: context, builder: (ctx) => const _NewTaskDialog());
  }

  @override
  Widget build(BuildContext context) {
    final tasks = ref.watch(tasksProvider);
    final isLoading = ref.watch(tasksLoadingProvider);
    final error = ref.watch(tasksErrorProvider);
    final filter = ref.watch(tasksFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const GroupSelectorTitle(section: 'Задачи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: isLoading ? null : _refreshTasks,
          ),
        ],
      ),
      body: Column(
        children: [
          SearchField(
            hintText: 'Поиск задач...',
            initialValue: ref.read(tasksSearchProvider),
            onChanged: (v) =>
                ref.read(tasksSearchProvider.notifier).state = v,
          ),
          Row(
            children: TaskFilter.values.map((f) {
              final isSelected = f == filter;
              return Expanded(
                child: InkWell(
                  onTap: () =>
                      ref.read(tasksFilterProvider.notifier).state = f,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      f.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: isSelected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTasks,
              child: isLoading && tasks.isEmpty
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
                                onPressed: _refreshTasks,
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : tasks.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 120),
                                Icon(Icons.task_alt_outlined,
                                    size: 64,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text('Нет задач',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                ),
                                const SizedBox(height: 8),
                                Center(
                                  child: Text('Нажмите + чтобы создать',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: tasks.length,
                              itemBuilder: (context, index) =>
                                  _TaskCard(task: tasks[index]),
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewTaskDialog,
        icon: const Icon(Icons.add),
        label: const Text('Новая задача'),
      ),
    );
  }
}

class _TaskCard extends ConsumerStatefulWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  ConsumerState<_TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends ConsumerState<_TaskCard> {
  final _subtaskController = TextEditingController();
  final _editSubtaskController = TextEditingController();
  bool _addingSubtask = false;
  String? _editingSubtaskId;

  @override
  void dispose() {
    _subtaskController.dispose();
    _editSubtaskController.dispose();
    super.dispose();
  }

  bool get _canDelete {
    final task = widget.task;
    if (task.isMine) return true;
    final current = ref.read(currentGroupProvider);
    return current?.isAdmin ?? false;
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _EditTaskDialog(task: widget.task),
    );
  }

  Future<void> _addSubtask() async {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    await ref.read(tasksProvider.notifier).addSubtask(widget.task.id, title);
    _subtaskController.clear();
    setState(() => _addingSubtask = false);
  }

  void _startEditSubtask(Task sub) {
    _editSubtaskController.text = sub.title;
    setState(() => _editingSubtaskId = sub.id);
  }

  Future<void> _saveSubtaskEdit(Task sub) async {
    final title = _editSubtaskController.text.trim();
    if (title.isEmpty) return;
    await ref
        .read(tasksProvider.notifier)
        .updateSubtask(widget.task.id, sub.id, title);
    setState(() => _editingSubtaskId = null);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final notifier = ref.read(tasksProvider.notifier);
    final hasSubtasks = task.subtasks.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            leading: Checkbox(
              value: task.isCompleted,
              onChanged: (_) => notifier.toggleComplete(task.id),
            ),
            title: Text(
              task.title,
              style: TextStyle(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (task.description != null && task.description!.isNotEmpty)
                  Text(task.description!,
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _PriorityBadge(priority: task.priority),
                    if (task.isShared)
                      const _Chip(icon: Icons.group, label: 'Общее'),
                    if (!task.isMine && task.authorName != null)
                      _Chip(icon: Icons.person, label: task.authorName!),
                    if (task.dueDate != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14,
                              color: task.isOverdue
                                  ? Theme.of(context).colorScheme.error
                                  : null),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd.MM.yyyy').format(task.dueDate!),
                            style: TextStyle(
                              color: task.isOverdue
                                  ? Theme.of(context).colorScheme.error
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    if (hasSubtasks)
                      Text('Подзадачи: ${task.completedSubtasks}/${task.subtasks.length}',
                          style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) async {
                switch (value) {
                  case 'edit':
                    _showEditDialog();
                    break;
                  case 'subtask':
                    setState(() => _addingSubtask = true);
                    break;
                  case 'delete':
                    await notifier.deleteTask(task.id);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
                if (task.parentId == null)
                  const PopupMenuItem(
                      value: 'subtask', child: Text('Добавить подзадачу')),
                if (_canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Удалить', style: TextStyle(color: Colors.red)),
                  ),
              ],
            ),
            onTap: _showEditDialog,
          ),
          if (hasSubtasks)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 8, bottom: 4),
              child: Column(
                children: task.subtasks.map((sub) {
                  final isEditing = _editingSubtaskId == sub.id;
                  return Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Checkbox(
                          value: sub.isCompleted,
                          onChanged: (_) => notifier.toggleComplete(sub.id),
                        ),
                      ),
                      Expanded(
                        child: isEditing
                            ? TextField(
                                controller: _editSubtaskController,
                                autofocus: true,
                                decoration: const InputDecoration(
                                  isDense: true,
                                ),
                                onSubmitted: (_) => _saveSubtaskEdit(sub),
                              )
                            : Text(
                                sub.title,
                                style: TextStyle(
                                  decoration: sub.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                      ),
                      if (isEditing) ...[
                        IconButton(
                          icon: const Icon(Icons.check, size: 18),
                          onPressed: () => _saveSubtaskEdit(sub),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () =>
                              setState(() => _editingSubtaskId = null),
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => _startEditSubtask(sub),
                        ),
                        if (_canDelete)
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () => notifier.deleteSubtask(
                                task.id, sub.id),
                          ),
                      ],
                    ],
                  );
                }).toList(),
              ),
            ),
          if (_addingSubtask)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Название подзадачи',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: _addSubtask,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _addingSubtask = false),
                  ),
                ],
              ),
            ),
          if (task.parentId == null && !hasSubtasks && !_addingSubtask)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _addingSubtask = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Подзадача'),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _PriorityBadge extends StatelessWidget {
  final TaskPriority priority;
  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (priority) {
      case TaskPriority.low:
        color = Colors.green;
        icon = Icons.arrow_downward;
        label = 'Низкий';
        break;
      case TaskPriority.medium:
        color = Colors.orange;
        icon = Icons.remove;
        label = 'Средний';
        break;
      case TaskPriority.high:
        color = Colors.red;
        icon = Icons.arrow_upward;
        label = 'Высокий';
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
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

class _NewTaskDialog extends ConsumerStatefulWidget {
  const _NewTaskDialog();

  @override
  ConsumerState<_NewTaskDialog> createState() => _NewTaskDialogState();
}

class _NewTaskDialogState extends ConsumerState<_NewTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;
  ItemVisibility _visibility = ItemVisibility.personal;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inGroup = ref.watch(currentGroupProvider) != null;

    return AlertDialog(
      title: const Text('Новая задача'),
      content: Form(
        key: _formKey,
        child: AppScrollbar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Приоритет',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(
                        value: p, child: Text(_priorityLabel(p))))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дедлайн',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_dueDate == null
                      ? 'Не выбран'
                      : DateFormat('dd.MM.yyyy').format(_dueDate!)),
                ),
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
            final task = Task(
              id: '',
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              priority: _priority,
              dueDate: _dueDate,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            await ref
                .read(tasksProvider.notifier)
                .createTask(task, visibility: _visibility);
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _EditTaskDialog extends ConsumerStatefulWidget {
  final Task task;
  const _EditTaskDialog({required this.task});

  @override
  ConsumerState<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<_EditTaskDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late TaskPriority _priority;
  late DateTime? _dueDate;
  late ItemVisibility _visibility;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController =
        TextEditingController(text: widget.task.description ?? '');
    _priority = widget.task.priority;
    _dueDate = widget.task.dueDate;
    _visibility = widget.task.visibility;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inGroup = widget.task.groupId != null;
    final current = ref.watch(currentGroupProvider);
    final canChangeVisibility =
        inGroup && (widget.task.isMine || (current?.isAdmin ?? false));

    return AlertDialog(
      title: const Text('Редактировать задачу'),
      content: Form(
        key: _formKey,
        child: AppScrollbar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Приоритет',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: TaskPriority.values
                    .map((p) => DropdownMenuItem(
                        value: p, child: Text(_priorityLabel(p))))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _dueDate = date);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Дедлайн',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(_dueDate == null
                      ? 'Не выбран'
                      : DateFormat('dd.MM.yyyy').format(_dueDate!)),
                ),
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
            final updated = widget.task.copyWith(
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              priority: _priority,
              dueDate: _dueDate,
              updatedAt: DateTime.now(),
            );
            await ref.read(tasksProvider.notifier).updateTask(
                  updated,
                  visibility: canChangeVisibility &&
                          _visibility != widget.task.visibility
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

String _priorityLabel(TaskPriority p) {
  switch (p) {
    case TaskPriority.low:
      return 'Низкий';
    case TaskPriority.medium:
      return 'Средний';
    case TaskPriority.high:
      return 'Высокий';
  }
}

extension on TaskFilter {
  String get label {
    switch (this) {
      case TaskFilter.all:
        return 'Все';
      case TaskFilter.active:
        return 'Активные';
      case TaskFilter.completed:
        return 'Выполненные';
    }
  }
}
