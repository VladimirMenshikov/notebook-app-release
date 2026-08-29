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
    // Обновим список групп при открытии меню.
    ref.read(groupsProvider.notifier).load();

    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Consumer(builder: (ctx, ref, _) {
          final groups = ref.watch(groupsProvider);
          final current = ref.watch(currentGroupProvider);
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Контекст',
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
                ...groups.where((g) => !g.isBanned).map((g) => ListTile(
                      leading: const Icon(Icons.group),
                      title: Text(g.name),
                      subtitle: Text(
                        '${g.membersCount} участн.'
                        '${g.isAdmin ? ' · админ' : ''}',
                      ),
                      trailing:
                          current?.id == g.id ? const Icon(Icons.check) : null,
                      onTap: () {
                        ref.read(currentGroupProvider.notifier).select(g);
                        Navigator.pop(ctx);
                      },
                    )),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('Управление группами'),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.push('/groups');
                  },
                ),
              ],
            ),
          );
        });
      },
    );
  }
}
