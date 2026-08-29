import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';

/// Заголовок AppBar с переключателем контекста «Личное / Группа».
/// Используется во всех разделах (Заметки/Задачи/Вопросы/Желания).
class GroupSelectorTitle extends ConsumerWidget {
  final String section;
  const GroupSelectorTitle({super.key, required this.section});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentGroupProvider);
    final invitations = ref.watch(myInvitationsProvider);
    final invCount = invitations.asData?.value.length ?? 0;

    return InkWell(
      onTap: () => _openMenu(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(section, style: const TextStyle(fontSize: 18)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        current == null ? Icons.person : Icons.group,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          current?.name ?? 'Личное',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down),
            if (invCount > 0)
              Container(
                margin: const EdgeInsets.only(left: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$invCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMenu(BuildContext context, WidgetRef ref) async {
    // Обновим список групп и приглашений при открытии меню.
    ref.read(groupsProvider.notifier).load();
    ref.invalidate(myInvitationsProvider);

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Consumer(builder: (ctx, ref, _) {
          final groups = ref.watch(groupsProvider);
          final current = ref.watch(currentGroupProvider);
          final invitations =
              ref.watch(myInvitationsProvider).asData?.value ?? const [];
          return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Контекст', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Личное'),
                trailing: current == null ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(currentGroupProvider.notifier).select(null);
                  Navigator.pop(ctx);
                },
              ),
              ...groups.map((g) => ListTile(
                    leading: const Icon(Icons.group),
                    title: Text(g.name),
                    subtitle: Text(
                      '${g.membersCount} участн.'
                      '${g.isAdmin ? ' · админ' : ''}',
                    ),
                    trailing: current?.id == g.id
                        ? const Icon(Icons.check)
                        : IconButton(
                            icon: const Icon(Icons.settings, size: 20),
                            onPressed: () {
                              Navigator.pop(ctx);
                              context.push('/groups/${g.id}');
                            },
                          ),
                    onTap: () {
                      ref.read(currentGroupProvider.notifier).select(g);
                      Navigator.pop(ctx);
                    },
                  )),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add),
                title: const Text('Создать группу'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showCreateGroupDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.mail_outline),
                title: Text('Мои приглашения${invitations.isNotEmpty ? ' (${invitations.length})' : ''}'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/invitations');
                },
              ),
            ],
          ),
        );
        });
      },
    );
  }

  Future<void> _showCreateGroupDialog(
      BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новая группа'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Название группы'),
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
    if (name == null || name.isEmpty) return;
    final group = await ref.read(groupsProvider.notifier).create(name);
    if (group != null) {
      ref.read(currentGroupProvider.notifier).select(group);
    }
  }
}
