import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';

/// Диалог создания группы. Создаёт группу и делает её текущим контекстом.
/// Возвращает созданную группу либо null (отмена / ошибка).
Future<Group?> showCreateGroupDialog(
  BuildContext context,
  WidgetRef ref,
) async {
  final controller = TextEditingController();
  final name = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Новая группа'),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Название группы'),
        onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text.trim()),
          child: const Text('Создать'),
        ),
      ],
    ),
  );
  if (name == null || name.isEmpty) return null;

  final group = await ref.read(groupsProvider.notifier).create(name);
  if (group != null) {
    ref.read(currentGroupProvider.notifier).select(group);
  }
  return group;
}
