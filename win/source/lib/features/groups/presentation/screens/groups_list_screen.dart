import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/groups/presentation/widgets/create_group_dialog.dart';

/// Раздел «Мои группы» (Профиль → Мои группы): список всех групп пользователя,
/// создание группы, переход к управлению, выход из группы, свои приглашения.
class GroupsListScreen extends ConsumerStatefulWidget {
  const GroupsListScreen({super.key});

  @override
  ConsumerState<GroupsListScreen> createState() => _GroupsListScreenState();
}

class _GroupsListScreenState extends ConsumerState<GroupsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsProvider.notifier).load();
      ref.invalidate(myInvitationsProvider);
    });
  }

  Future<void> _refresh() async {
    await ref.read(groupsProvider.notifier).load();
    ref.invalidate(myInvitationsProvider);
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirm(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Отмена')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Да')),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _leave(Group g) async {
    if (!await _confirm('Выйти из группы «${g.name}»?')) return;
    try {
      await ref.read(apiClientProvider).leaveGroup(g.id);
      final current = ref.read(currentGroupProvider);
      if (current?.id == g.id) {
        ref.read(currentGroupProvider.notifier).select(null);
      }
      await _refresh();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
  }

  Future<void> _delete(Group g) async {
    if (!await _confirm('Удалить группу «${g.name}» со всем общим содержимым?')) {
      return;
    }
    try {
      await ref.read(apiClientProvider).deleteGroup(g.id);
      final current = ref.read(currentGroupProvider);
      if (current?.id == g.id) {
        ref.read(currentGroupProvider.notifier).select(null);
      }
      await _refresh();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsProvider);
    final loading = ref.watch(groupsLoadingProvider);
    final error = ref.watch(groupsErrorProvider);
    final invitations = ref.watch(myInvitationsProvider);
    final invCount = invitations.asData?.value.length ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Мои группы')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final g = await showCreateGroupDialog(context, ref);
          if (g != null && mounted) _snack('Группа «${g.name}» создана');
        },
        icon: const Icon(Icons.add),
        label: const Text('Создать группу'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 88),
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Мои приглашения'),
              trailing: invCount > 0
                  ? Chip(label: Text('$invCount'))
                  : const Icon(Icons.chevron_right),
              onTap: () => context.push('/invitations'),
            ),
            const Divider(height: 1),
            if (loading && groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null && groups.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(error, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton(
                        onPressed: _refresh,
                        child: const Text('Повторить')),
                  ],
                ),
              )
            else if (groups.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Text('Вы пока не состоите ни в одной группе'),
                ),
              )
            else
              ...groups.map(_groupTile),
          ],
        ),
      ),
    );
  }

  Widget _groupTile(Group g) {
    final subtitleParts = <String>[
      '${g.membersCount} участн.',
      if (g.isOwner) 'создатель' else if (g.isAdmin) 'админ',
    ];
    return ListTile(
      leading: const Icon(Icons.group),
      title: Text(g.name),
      subtitle: Text(
        g.isBanned
            ? 'заблокирован${g.bannedUntil != null ? ' до ${_d(g.bannedUntil!)}' : ' бессрочно'}'
            : subtitleParts.join(' · '),
        style: g.isBanned
            ? TextStyle(color: Theme.of(context).colorScheme.error)
            : null,
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'leave') _leave(g);
          if (v == 'delete') _delete(g);
        },
        itemBuilder: (ctx) => [
          if (g.isOwner)
            const PopupMenuItem(value: 'delete', child: Text('Удалить группу'))
          else
            const PopupMenuItem(value: 'leave', child: Text('Выйти из группы')),
        ],
      ),
      onTap: g.isBanned ? null : () => context.push('/groups/${g.id}'),
    );
  }

  String _d(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
}
