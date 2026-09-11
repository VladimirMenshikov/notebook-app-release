import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/core/update/update_service.dart';

final updateServiceProvider = Provider<UpdateService>((ref) {
  return UpdateService(ref.read(apiClientProvider));
});

/// Проверяет наличие обновления и, если оно есть, предлагает установить.
/// [silent] = true (по умолчанию) — ничего не показывать, если обновлений
/// нет или проверка не удалась (используется при автопроверке на старте).
/// [silent] = false — показать снэкбар с результатом в любом случае
/// (используется при ручной проверке из настроек).
Future<void> checkForUpdateAndPrompt(
  BuildContext context,
  WidgetRef ref, {
  bool silent = true,
}) async {
  final updateService = ref.read(updateServiceProvider);
  if (!updateService.isSupportedPlatform) return;

  UpdateInfo? update;
  try {
    update = await updateService.checkForUpdate();
  } catch (e) {
    if (!silent && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    }
    return;
  }

  if (!context.mounted) return;

  if (update == null) {
    if (!silent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('У вас установлена последняя версия')),
      );
    }
    return;
  }

  final shouldUpdate = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Доступно обновление'),
      content: Text('Версия ${update!.version}. Установить сейчас?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Позже'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Обновить'),
        ),
      ],
    ),
  );

  if (shouldUpdate != true || !context.mounted) return;

  await _downloadAndInstall(context, updateService, update.apkUrl);
}

Future<void> _downloadAndInstall(
  BuildContext context,
  UpdateService updateService,
  String apkUrl,
) async {
  final progress = ValueNotifier<double>(0);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Загрузка обновления'),
      content: ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (ctx, value, _) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(value: value > 0 ? value : null),
            const SizedBox(height: 12),
            Text('${(value * 100).toStringAsFixed(0)}%'),
          ],
        ),
      ),
    ),
  );

  try {
    await updateService.downloadAndInstall(
      apkUrl,
      onProgress: (value) => progress.value = value,
    );
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(friendlyErrorMessage(e))),
      );
    }
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}
