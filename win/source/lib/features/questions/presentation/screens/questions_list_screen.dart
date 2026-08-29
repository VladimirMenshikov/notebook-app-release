import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notebook_app/core/widgets/search_field.dart';
import 'package:notebook_app/features/groups/domain/group_model.dart';
import 'package:notebook_app/features/groups/presentation/providers/groups_providers.dart';
import 'package:notebook_app/features/groups/presentation/widgets/group_selector_title.dart';
import 'package:notebook_app/features/questions/presentation/providers/questions_providers.dart';
import 'package:notebook_app/features/questions/domain/question_model.dart';

class QuestionsListScreen extends ConsumerStatefulWidget {
  const QuestionsListScreen({super.key});

  @override
  ConsumerState<QuestionsListScreen> createState() =>
      _QuestionsListScreenState();
}

class _QuestionsListScreenState extends ConsumerState<QuestionsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(questionsProvider.notifier).loadQuestions(refresh: true);
    });
  }

  Future<void> _refreshQuestions() async {
    await ref.read(questionsProvider.notifier).loadQuestions(refresh: true);
  }

  void _showNewQuestionDialog() {
    showDialog(context: context, builder: (ctx) => const _NewQuestionDialog());
  }

  void _showEditQuestionDialog(Question question) {
    showDialog(
        context: context,
        builder: (ctx) => _EditQuestionDialog(question: question));
  }

  @override
  Widget build(BuildContext context) {
    final questions = ref.watch(questionsProvider);
    final isLoading = ref.watch(questionsLoadingProvider);
    final error = ref.watch(questionsErrorProvider);
    final filter = ref.watch(questionsFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const GroupSelectorTitle(section: 'Вопросы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: isLoading ? null : _refreshQuestions,
          ),
        ],
      ),
      body: Column(
        children: [
          SearchField(
            hintText: 'Поиск вопросов...',
            initialValue: ref.read(questionsSearchProvider),
            onChanged: (v) =>
                ref.read(questionsSearchProvider.notifier).state = v,
          ),
          Row(
            children: [
              _FilterChip(
                label: 'Все',
                isSelected: filter == null,
                onTap: () =>
                    ref.read(questionsFilterProvider.notifier).state = null,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Без ответа',
                isSelected: filter == false,
                onTap: () =>
                    ref.read(questionsFilterProvider.notifier).state = false,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'С ответом',
                isSelected: filter == true,
                onTap: () =>
                    ref.read(questionsFilterProvider.notifier).state = true,
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshQuestions,
              child: isLoading && questions.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48),
                              const SizedBox(height: 16),
                              Text(error),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _refreshQuestions,
                                child: const Text('Повторить'),
                              ),
                            ],
                          ),
                        )
                      : questions.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 120),
                                Icon(Icons.help_outline,
                                    size: 64,
                                    color:
                                        Theme.of(context).colorScheme.outline),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text('Нет вопросов',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: questions.length,
                              itemBuilder: (context, index) =>
                                  _buildQuestionCard(questions[index]),
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewQuestionDialog,
        icon: const Icon(Icons.add),
        label: const Text('Новый вопрос'),
      ),
    );
  }

  Widget _buildQuestionCard(Question question) {
    final current = ref.read(currentGroupProvider);
    final canDelete = question.isMine || (current?.isAdmin ?? false);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showEditQuestionDialog(question),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    question.isAnswered
                        ? Icons.check_circle
                        : Icons.help_outline,
                    color: question.isAnswered
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(question.question,
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      final notifier = ref.read(questionsProvider.notifier);
                      switch (value) {
                        case 'edit':
                          _showEditQuestionDialog(question);
                          break;
                        case 'answer':
                          await notifier.toggleAnswered(question.id);
                          break;
                        case 'delete':
                          await notifier.deleteQuestion(question.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'edit', child: Text('Редактировать')),
                      PopupMenuItem(
                        value: 'answer',
                        child: Text(question.isAnswered
                            ? 'Снять отметку ответа'
                            : 'Отметить отвеченным'),
                      ),
                      if (canDelete)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Удалить',
                              style: TextStyle(color: Colors.red)),
                        ),
                    ],
                  ),
                ],
              ),
              if (question.isShared || (!question.isMine && question.authorName != null)) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    if (question.isShared)
                      const Chip(
                        avatar: Icon(Icons.group, size: 14),
                        label: Text('Общее', style: TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                    if (!question.isMine && question.authorName != null)
                      Chip(
                        avatar: const Icon(Icons.person, size: 14),
                        label: Text(question.authorName!,
                            style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
              if (question.answer != null && question.answer!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Ответ:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          )),
                      const SizedBox(height: 4),
                      Text(question.answer!,
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(question.updatedAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : null,
              fontWeight: isSelected ? FontWeight.bold : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _NewQuestionDialog extends ConsumerStatefulWidget {
  const _NewQuestionDialog();

  @override
  ConsumerState<_NewQuestionDialog> createState() => _NewQuestionDialogState();
}

class _NewQuestionDialogState extends ConsumerState<_NewQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  ItemVisibility _visibility = ItemVisibility.personal;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inGroup = ref.watch(currentGroupProvider) != null;

    return AlertDialog(
      title: const Text('Новый вопрос'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Ваш вопрос',
                prefixIcon: Icon(Icons.help_outline),
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Введите вопрос' : null,
            ),
            if (inGroup) ...[
              const SizedBox(height: 16),
              _VisibilitySelector(
                value: _visibility,
                onChanged: (v) => setState(() => _visibility = v),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            await ref.read(questionsProvider.notifier).createQuestion(
                  _questionController.text.trim(),
                  visibility: _visibility,
                );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Создать'),
        ),
      ],
    );
  }
}

class _EditQuestionDialog extends ConsumerStatefulWidget {
  final Question question;
  const _EditQuestionDialog({required this.question});

  @override
  ConsumerState<_EditQuestionDialog> createState() =>
      _EditQuestionDialogState();
}

class _EditQuestionDialogState extends ConsumerState<_EditQuestionDialog> {
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  late ItemVisibility _visibility;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.question.question);
    _answerController =
        TextEditingController(text: widget.question.answer ?? '');
    _visibility = widget.question.visibility;
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentGroupProvider);
    final canChangeVisibility = widget.question.groupId != null &&
        (widget.question.isMine || (current?.isAdmin ?? false));

    return AlertDialog(
      title: const Text('Редактировать вопрос'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Вопрос',
                  prefixIcon: Icon(Icons.help_outline),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'Введите вопрос' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Ответ',
                  prefixIcon: Icon(Icons.question_answer),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              if (canChangeVisibility) ...[
                const SizedBox(height: 16),
                _VisibilitySelector(
                  value: _visibility,
                  onChanged: (v) => setState(() => _visibility = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () async {
            if (!_formKey.currentState!.validate()) return;
            final answer = _answerController.text.trim();
            final updated = widget.question.copyWith(
              question: _questionController.text.trim(),
              answer: answer.isEmpty ? null : answer,
              isAnswered: answer.isNotEmpty,
              updatedAt: DateTime.now(),
            );
            await ref.read(questionsProvider.notifier).updateQuestion(
                  updated,
                  visibility: canChangeVisibility &&
                          _visibility != widget.question.visibility
                      ? _visibility
                      : null,
                );
            if (context.mounted) Navigator.of(context).pop();
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _VisibilitySelector extends StatelessWidget {
  final ItemVisibility value;
  final ValueChanged<ItemVisibility> onChanged;
  const _VisibilitySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ItemVisibility>(
      segments: const [
        ButtonSegment(
          value: ItemVisibility.personal,
          label: Text('Личное'),
          icon: Icon(Icons.person),
        ),
        ButtonSegment(
          value: ItemVisibility.shared,
          label: Text('Общее'),
          icon: Icon(Icons.group),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}
