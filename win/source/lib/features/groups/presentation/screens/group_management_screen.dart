import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  final String groupId;
  const GroupManagementScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupManagementScreen> createState() =>
      _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  GroupDetail? _detail;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(apiClientProvider);
      final json = await api.getGroup(widget.groupId);
      if (!mounted) return;
      setState(() {
        _detail = GroupDetail.fromJson(json);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(e);
        _loading = false;
      });
    }
  }

  Future<void> _syncGroups() =>
      ref.read(groupsProvider.notifier).refreshAfterChange();

  Future<void> _rename() async {
    final controller = TextEditingController(text: _detail!.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Переименовать группу'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    try {
      await ref.read(apiClientProvider).renameGroup(widget.groupId, name);
      await _load();
      await _syncGroups();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
  }

  Future<void> _invite() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пригласить по email'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(labelText: 'Email участника'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Пригласить'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty) return;
    try {
      await ref.read(apiClientProvider).inviteToGroup(widget.groupId, email);
      _snack('Приглашение отправлено');
      await _load();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
  }

  Future<void> _revoke(GroupInvitationInfo inv) async {
    try {
      await ref
          .read(apiClientProvider)
          .revokeInvitation(widget.groupId, inv.id);
      await _load();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
  }

  Future<void> _removeMember(GroupMember member) async {
    final confirmed = await _confirm(
        'Удалить участника ${member.name ?? member.email} из группы?');
    if (!confirmed) return;
    try {
      await ref
          .read(apiClientProvider)
          .removeGroupMember(widget.groupId, member.userId);
      await _load();
      await _syncGroups();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
  }

  Future<void> _leave() async {
    final confirmed = await _confirm('Выйти из группы «${_detail!.name}»?');
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).leaveGroup(widget.groupId);
      ref.read(currentGroupProvider.notifier).select(null);
      unawaited(_syncGroups());
      if (mounted) context.pop();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed =
        await _confirm('Удалить группу «${_detail!.name}» со всем общим содержимым?');
    if (!confirmed) return;
    try {
      await ref.read(apiClientProvider).deleteGroup(widget.groupId);
      ref.read(currentGroupProvider.notifier).select(null);
      unawaited(_syncGroups());
      if (mounted) context.pop();
    } catch (e) {
      _snack(friendlyErrorMessage(e));
    }
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

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.name ?? 'Группа'),
        actions: [
          if (detail != null && detail.isAdmin)
            IconButton(icon: const Icon(Icons.edit), onPressed: _rename),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Повторить')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text('Участники',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ...detail!.members.map(_memberTile),
                      const SizedBox(height: 24),
                      if (detail.isAdmin) ...[
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Заявки',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            TextButton.icon(
                              onPressed: _invite,
                              icon: const Icon(Icons.person_add),
                              label: const Text('Пригласить'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (detail.invitations.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Text('Нет ожидающих приглашений'),
                          )
                        else
                          ...detail.invitations.map(_invitationTile),
                        const SizedBox(height: 24),
                      ],
                      if (detail.isOwner)
                        OutlinedButton.icon(
                          onPressed: _deleteGroup,
                          icon: const Icon(Icons.delete_forever,
                              color: Colors.red),
                          label: const Text('Удалить группу',
                              style: TextStyle(color: Colors.red)),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _leave,
                          icon: const Icon(Icons.logout),
                          label: const Text('Выйти из группы'),
                        ),
                    ],
                  ),
                ),
    );
  }

  Widget _memberTile(GroupMember m) {
    return ListTile(
      leading: CircleAvatar(child: Text((m.name ?? m.email).characters.first.toUpperCase())),
      title: Text(m.name ?? m.email),
      subtitle: Text(
          '${m.email}${m.isOwner ? ' · создатель' : m.role == GroupRole.admin ? ' · админ' : ''}'),
      trailing: (_detail!.isAdmin && !m.isOwner)
          ? IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => _removeMember(m),
            )
          : null,
    );
  }

  Widget _invitationTile(GroupInvitationInfo inv) {
    return ListTile(
      leading: const Icon(Icons.mail_outline),
      title: Text(inv.email),
      subtitle: const Text('Ожидает ответа'),
      trailing: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => _revoke(inv),
      ),
    );
  }
}
