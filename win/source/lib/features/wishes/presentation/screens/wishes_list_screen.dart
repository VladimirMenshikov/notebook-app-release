import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:notebook_app/core/widgets/search_field.dart';
import 'package:notebook_app/features/groups/presentation/widgets/group_selector_title.dart';
import 'package:notebook_app/features/wishes/domain/wish_model.dart';
import 'package:notebook_app/features/wishes/presentation/providers/wishes_providers.dart';

class WishesListScreen extends ConsumerStatefulWidget {
  const WishesListScreen({super.key});

  @override
  ConsumerState<WishesListScreen> createState() => _WishesListScreenState();
}

class _WishesListScreenState extends ConsumerState<WishesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(wishesProvider.notifier).loadWishes(refresh: true);
    });
  }

  Future<void> _refresh() =>
      ref.read(wishesProvider.notifier).loadWishes(refresh: true);

  void _showNewWishDialog() {
    showDialog(context: context, builder: (_) => const _WishDialog());
  }

  void _showEditWishDialog(Wish wish) {
    showDialog(context: context, builder: (_) => _WishDialog(wish: wish));
  }

  @override
  Widget build(BuildContext context) {
    final wishes = ref.watch(wishesProvider);
    final isLoading = ref.watch(wishesLoadingProvider);
    final error = ref.watch(wishesErrorProvider);
    final filter = ref.watch(wishesFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const GroupSelectorTitle(section: 'Желания'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить',
            onPressed: isLoading ? null : _refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          SearchField(
            hintText: 'Поиск желаний...',
            initialValue: ref.read(wishesSearchProvider),
            onChanged: (v) =>
                ref.read(wishesSearchProvider.notifier).state = v,
          ),
          Row(
            children: WishFilter.values.map((f) {
              final selected = f == filter;
              return Expanded(
                child: InkWell(
                  onTap: () =>
                      ref.read(wishesFilterProvider.notifier).state = f,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      f.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: isLoading && wishes.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? _ErrorView(message: error, onRetry: _refresh)
                      : wishes.isEmpty
                          ? _EmptyView()
                          : ListView.builder(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: wishes.length,
                              itemBuilder: (context, index) =>
                                  _buildWishCard(wishes[index]),
                            ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewWishDialog,
        icon: const Icon(Icons.add),
        label: const Text('Новое желание'),
      ),
    );
  }

  Widget _buildWishCard(Wish wish) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _StatusIcon(status: wish.status),
        title: Text(
          wish.title,
          style: TextStyle(
            decoration: wish.status == WishStatus.cancelled
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (wish.description != null && wish.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(wish.description!,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 4),
            Text(
              '${wish.status.label} · ${DateFormat('dd.MM.yyyy').format(wish.updatedAt)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            final notifier = ref.read(wishesProvider.notifier);
            switch (value) {
              case 'edit':
                _showEditWishDialog(wish);
                break;
              case 'fulfilled':
                await notifier.setStatus(wish.id, WishStatus.fulfilled);
                break;
              case 'cancelled':
                await notifier.setStatus(wish.id, WishStatus.cancelled);
                break;
              case 'active':
                await notifier.setStatus(wish.id, WishStatus.active);
                break;
              case 'delete':
                await notifier.deleteWish(wish.id);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            if (wish.status != WishStatus.fulfilled)
              const PopupMenuItem(
                  value: 'fulfilled', child: Text('Отметить исполненным')),
            if (wish.status != WishStatus.cancelled)
              const PopupMenuItem(value: 'cancelled', child: Text('Отменить')),
            if (wish.status != WishStatus.active)
              const PopupMenuItem(
                  value: 'active', child: Text('Вернуть в активные')),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Удалить', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
        onTap: () => _showEditWishDialog(wish),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final WishStatus status;
  const _StatusIcon({required this.status});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case WishStatus.fulfilled:
        return const Icon(Icons.check_circle, color: Colors.green);
      case WishStatus.cancelled:
        return Icon(Icons.cancel, color: Theme.of(context).colorScheme.outline);
      case WishStatus.active:
        return Icon(Icons.card_giftcard,
            color: Theme.of(context).colorScheme.primary);
    }
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.card_giftcard,
            size: 64, color: Theme.of(context).colorScheme.outline),
        const SizedBox(height: 16),
        Center(
          child: Text('Нет желаний',
              style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Нажмите + чтобы добавить',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 16),
          Text(message),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}

class _WishDialog extends ConsumerStatefulWidget {
  final Wish? wish;
  const _WishDialog({this.wish});

  @override
  ConsumerState<_WishDialog> createState() => _WishDialogState();
}

class _WishDialogState extends ConsumerState<_WishDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late WishStatus _status;

  bool get _isEdit => widget.wish != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.wish?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.wish?.description ?? '');
    _status = widget.wish?.status ?? WishStatus.active;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEdit ? 'Редактировать желание' : 'Новое желание'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Название',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Введите название' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              if (_isEdit) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<WishStatus>(
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Статус',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  items: WishStatus.values
                      .map((s) => DropdownMenuItem(
                          value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (v) => setState(() => _status = v!),
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
            final notifier = ref.read(wishesProvider.notifier);
            final title = _titleController.text.trim();
            final description = _descriptionController.text.trim();
            if (_isEdit) {
              await notifier.updateWish(widget.wish!.copyWith(
                title: title,
                description: description,
                status: _status,
                updatedAt: DateTime.now(),
              ));
            } else {
              await notifier.createWish(title, description);
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(_isEdit ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
