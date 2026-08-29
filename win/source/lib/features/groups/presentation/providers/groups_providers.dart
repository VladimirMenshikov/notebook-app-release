import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/core/storage/local_storage.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';

final groupsLoadingProvider = StateProvider<bool>((ref) => false);
final groupsErrorProvider = StateProvider<String?>((ref) => null);

/// Текущий контекст разделов. `null` — «Личное».
final currentGroupProvider =
    StateNotifierProvider<CurrentGroupNotifier, Group?>((ref) {
  return CurrentGroupNotifier();
});

class CurrentGroupNotifier extends StateNotifier<Group?> {
  CurrentGroupNotifier() : super(null);

  final LocalStorage _storage = LocalStorage();

  void select(Group? group) {
    state = group;
    _storage.setCurrentGroupId(group?.id);
  }

  /// Тихо (без записи в хранилище) применить восстановленный контекст.
  /// Не трогаем state, если группа та же — иначе лишние перезагрузки списков.
  void restore(Group? group) {
    if (state?.id == group?.id) return;
    state = group;
  }
}

final groupsProvider =
    StateNotifierProvider<GroupsNotifier, List<Group>>((ref) {
  return GroupsNotifier(ref);
});

class GroupsNotifier extends StateNotifier<List<Group>> {
  final Ref _ref;
  final LocalStorage _storage = LocalStorage();

  GroupsNotifier(this._ref) : super([]);

  Future<void> load() async {
    _ref.read(groupsLoadingProvider.notifier).state = true;
    _ref.read(groupsErrorProvider.notifier).state = null;
    try {
      final api = _ref.read(apiClientProvider);
      final data = await api.getGroups();
      final groups = data
          .map((j) => Group.fromJson(j as Map<String, dynamic>))
          .toList();
      state = groups;
      await _syncCurrentGroup();
    } catch (e) {
      _ref.read(groupsErrorProvider.notifier).state = friendlyErrorMessage(e);
    } finally {
      _ref.read(groupsLoadingProvider.notifier).state = false;
    }
  }

  /// Согласовать выбранный контекст со списком групп: восстановить сохранённый
  /// либо сбросить на «Личное», если группа пропала (вышли/удалили).
  Future<void> _syncCurrentGroup() async {
    final notifier = _ref.read(currentGroupProvider.notifier);
    final current = _ref.read(currentGroupProvider);
    final storedId = current?.id ?? await _storage.getCurrentGroupId();
    if (storedId == null) {
      if (current != null) notifier.restore(null);
      return;
    }
    Group? match;
    for (final g in state) {
      if (g.id == storedId) {
        match = g;
        break;
      }
    }
    if (match == null) {
      notifier.select(null);
    } else {
      notifier.restore(match);
    }
  }

  Future<Group?> create(String name) async {
    try {
      final api = _ref.read(apiClientProvider);
      final json = await api.createGroup(name);
      final detail = GroupDetail.fromJson(json);
      await load();
      final created = state.firstWhere(
        (g) => g.id == detail.id,
        orElse: () => detail.toGroup(),
      );
      return created;
    } catch (e) {
      _ref.read(groupsErrorProvider.notifier).state = friendlyErrorMessage(e);
      return null;
    }
  }

  Future<void> refreshAfterChange() => load();
}

/// Приглашения, адресованные текущему пользователю.
final myInvitationsProvider =
    FutureProvider.autoDispose<List<MyInvitation>>((ref) async {
  final api = ref.read(apiClientProvider);
  final data = await api.getMyInvitations();
  return data
      .map((j) => MyInvitation.fromJson(j as Map<String, dynamic>))
      .toList();
});
