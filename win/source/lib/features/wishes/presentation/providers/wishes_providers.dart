import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/wishes/domain/wish_model.dart';

final wishesLoadingProvider = StateProvider<bool>((ref) => false);
final wishesErrorProvider = StateProvider<String?>((ref) => null);
final wishesFilterProvider = StateProvider<WishFilter>((ref) => WishFilter.all);
final wishesSearchProvider = StateProvider<String>((ref) => '');

final wishesProvider =
    StateNotifierProvider<WishesNotifier, List<Wish>>((ref) {
  return WishesNotifier(ref);
});

class WishesNotifier extends StateNotifier<List<Wish>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;

  WishesNotifier(this._ref) : super([]) {
    _ref.listen(wishesFilterProvider, (_, __) => loadWishes(refresh: true));
    _ref.listen(currentGroupProvider, (_, __) => loadWishes(refresh: true));
    _ref.listen(wishesSearchProvider, (_, __) {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => loadWishes(refresh: true),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> loadWishes({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = [];
      _hasMore = true;
    }

    _ref.read(wishesLoadingProvider.notifier).state = true;
    _ref.read(wishesErrorProvider.notifier).state = null;

    try {
      final api = _ref.read(apiClientProvider);
      final filter = _ref.read(wishesFilterProvider);
      final search = _ref.read(wishesSearchProvider);
      final group = _ref.read(currentGroupProvider);

      final response = await api.getWishes(
        page: _currentPage,
        limit: 50,
        status: filter.statusParam,
        groupId: group?.id,
        search: search,
      );

      final List<dynamic> data = response['data'] ?? [];
      final wishes = data
          .map((json) => Wish.fromJson(json as Map<String, dynamic>))
          .toList();

      state = refresh ? wishes : [...state, ...wishes];
      _hasMore = wishes.length >= 50;
    } catch (e) {
      _ref.read(wishesErrorProvider.notifier).state = friendlyErrorMessage(e);
    } finally {
      _ref.read(wishesLoadingProvider.notifier).state = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _currentPage++;
    await loadWishes();
  }

  Future<void> createWish(String title, String? description) async {
    try {
      final api = _ref.read(apiClientProvider);
      final group = _ref.read(currentGroupProvider);
      final created = await api.createWish({
        'title': title,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (group != null) 'groupId': group.id,
      });
      state = [Wish.fromJson(created), ...state];
    } catch (e) {
      _ref.read(wishesErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> updateWish(Wish wish) async {
    try {
      final api = _ref.read(apiClientProvider);
      final updated = await api.updateWish(wish.id, {
        'title': wish.title,
        'description': wish.description ?? '',
        'status': wishStatusToString(wish.status),
      });
      final result = Wish.fromJson(updated);
      _applyFilterAfterUpdate(result);
    } catch (e) {
      _ref.read(wishesErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> setStatus(String id, WishStatus status) async {
    final wish = state.firstWhere((w) => w.id == id);
    await updateWish(wish.copyWith(status: status));
  }

  Future<void> deleteWish(String id) async {
    try {
      final api = _ref.read(apiClientProvider);
      await api.deleteWish(id);
      state = state.where((w) => w.id != id).toList();
    } catch (e) {
      _ref.read(wishesErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  /// После смены статуса запись может выпасть из активного фильтра.
  void _applyFilterAfterUpdate(Wish updated) {
    final filter = _ref.read(wishesFilterProvider);
    final matches = filter == WishFilter.all ||
        wishStatusToString(updated.status) == filter.statusParam;
    if (matches) {
      state = state.map((w) => w.id == updated.id ? updated : w).toList();
    } else {
      state = state.where((w) => w.id != updated.id).toList();
    }
  }
}
