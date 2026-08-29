import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/questions/domain/question_model.dart';

final questionsLoadingProvider = StateProvider<bool>((ref) => false);
final questionsErrorProvider = StateProvider<String?>((ref) => null);
final questionsFilterProvider = StateProvider<bool?>((ref) => null);
final questionsSearchProvider = StateProvider<String>((ref) => '');

final questionsProvider =
    StateNotifierProvider<QuestionsNotifier, List<Question>>((ref) {
  return QuestionsNotifier(ref);
});

class QuestionsNotifier extends StateNotifier<List<Question>> {
  final Ref _ref;
  int _currentPage = 1;
  bool _hasMore = true;
  Timer? _debounce;

  QuestionsNotifier(this._ref) : super([]) {
    _ref.listen(questionsFilterProvider, (_, __) => loadQuestions(refresh: true));
    _ref.listen(currentGroupProvider, (_, __) => loadQuestions(refresh: true));
    _ref.listen(questionsSearchProvider, (_, __) {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 300),
        () => loadQuestions(refresh: true),
      );
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  bool? get currentFilter => _ref.read(questionsFilterProvider);

  Future<void> loadQuestions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = [];
      _hasMore = true;
    }

    _ref.read(questionsLoadingProvider.notifier).state = true;
    _ref.read(questionsErrorProvider.notifier).state = null;

    try {
      final apiClient = _ref.read(apiClientProvider);
      final group = _ref.read(currentGroupProvider);
      final search = _ref.read(questionsSearchProvider);

      final response = await apiClient.getQuestions(
        page: _currentPage,
        limit: 50,
        answered: currentFilter,
        groupId: group?.id,
        search: search,
      );

      final List<dynamic> questionsData = response['data'] ?? [];
      final List<Question> questions = questionsData
          .map((json) => Question.fromJson(json as Map<String, dynamic>))
          .toList();

      state = refresh ? questions : [...state, ...questions];
      _hasMore = questions.length >= 50;
    } catch (e) {
      _ref.read(questionsErrorProvider.notifier).state = friendlyErrorMessage(e);
    } finally {
      _ref.read(questionsLoadingProvider.notifier).state = false;
    }
  }

  Future<void> loadMore() async {
    if (!_hasMore) return;
    _currentPage++;
    await loadQuestions();
  }

  Future<void> createQuestion(
    String question, {
    ItemVisibility visibility = ItemVisibility.personal,
  }) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final group = _ref.read(currentGroupProvider);
      final created = await apiClient.createQuestion({
        'question': question,
        if (group != null) 'groupId': group.id,
        if (group != null) 'visibility': visibilityToString(visibility),
      });
      state = [Question.fromJson(created), ...state];
    } catch (e) {
      _ref.read(questionsErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> updateQuestion(Question question,
      {ItemVisibility? visibility}) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      final updated = await apiClient.updateQuestion(question.id, {
        'question': question.question,
        'answer': question.answer,
        'isAnswered': question.isAnswered,
        if (visibility != null) 'visibility': visibilityToString(visibility),
      });
      final result = Question.fromJson(updated);
      state = state.map((q) => q.id == question.id ? result : q).toList();
    } catch (e) {
      _ref.read(questionsErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> deleteQuestion(String id) async {
    try {
      final apiClient = _ref.read(apiClientProvider);
      await apiClient.deleteQuestion(id);
      state = state.where((q) => q.id != id).toList();
    } catch (e) {
      _ref.read(questionsErrorProvider.notifier).state = friendlyErrorMessage(e);
    }
  }

  Future<void> toggleAnswered(String id) async {
    final question = state.firstWhere((q) => q.id == id);
    await updateQuestion(question.copyWith(isAnswered: !question.isAnswered));
  }
}
