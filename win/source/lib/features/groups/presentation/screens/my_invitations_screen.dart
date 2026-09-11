import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';

class MyInvitationsScreen extends ConsumerWidget {
  const MyInvitationsScreen({super.key});

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    String token, {
    required bool accept,
  }) async {
    try {
      await ref.read(apiClientProvider).respondInvitation(token, accept: accept);
      ref.invalidate(myInvitationsProvider);
      await ref.read(groupsProvider.notifier).load();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Вы вступили в группу' : 'Приглашение отклонено')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyErrorMessage(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitations = ref.watch(myInvitationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои приглашения')),
      body: invitations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(friendlyErrorMessage(e))),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Нет приглашений'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myInvitationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final inv = list[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(inv.groupName,
                            style: Theme.of(context).textTheme.titleMedium),
                        if (inv.invitedByName != null)
                          Text('Пригласил: ${inv.invitedByName}',
                              style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _respond(context, ref, inv.token,
                                  accept: false),
                              child: const Text('Отклонить'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => _respond(context, ref, inv.token,
                                  accept: true),
                              child: const Text('Принять'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
