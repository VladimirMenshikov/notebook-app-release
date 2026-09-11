import 'package:notebook_app/features/groups/domain/group_model.dart';

enum TaskPriority { low, medium, high }

enum TaskFilter { all, active, completed }

class Task {
  final String id;
  final String title;
  final String? description;
  final bool isCompleted;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? groupId;
  final ItemVisibility visibility;
  final String? parentId;
  final List<Task> subtasks;
  final String? authorName;
  final bool isMine;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.groupId,
    this.visibility = ItemVisibility.personal,
    this.parentId,
    this.subtasks = const [],
    this.authorName,
    this.isMine = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      priority: TaskPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      groupId: json['groupId'] as String?,
      visibility: visibilityFromString(json['visibility'] as String?),
      parentId: json['parentId'] as String?,
      subtasks: (json['subtasks'] as List? ?? [])
          .map((s) => Task.fromJson(s as Map<String, dynamic>))
          .toList(),
      authorName: json['authorName'] as String?,
      isMine: json['isMine'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    TaskPriority? priority,
    DateTime? dueDate,
    ItemVisibility? visibility,
    List<Task>? subtasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      groupId: groupId,
      visibility: visibility ?? this.visibility,
      parentId: parentId,
      subtasks: subtasks ?? this.subtasks,
      authorName: authorName,
      isMine: isMine,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isShared => visibility == ItemVisibility.shared;

  int get completedSubtasks => subtasks.where((s) => s.isCompleted).length;

  String get priorityName {
    switch (priority) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.medium:
        return 'Средний';
      case TaskPriority.high:
        return 'Высокий';
    }
  }

  bool get isOverdue =>
      !isCompleted && dueDate != null && dueDate!.isBefore(DateTime.now());
}
