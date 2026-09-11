import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/network/api_error.dart';
import 'package:notebook_app/core/auth/biometric_service.dart';
import 'package:notebook_app/core/storage/local_storage.dart';
import 'package:notebook_app/core/update/update_prompt.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
      ),
      body: ListView(
        children: [
          // Theme section
          const _SectionTitle(title: 'Отображение'),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ThemeModeTile(),
              ],
            ),
          ),
          
          // Security section
          const _SectionTitle(title: 'Безопасность'),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                _TwoFactorTile(),
                const Divider(height: 1),
                const _BiometricLoginTile(),
              ],
            ),
          ),
          
          // Account section
          const _SectionTitle(title: 'Аккаунт'),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ChangePasswordTile(),
              ],
            ),
          ),
          
          // About section
          const _SectionTitle(title: 'О приложении'),
          Card(
            margin: const EdgeInsets.all(16),
            child: Column(
              children: [
                const _VersionTile(),
                const Divider(),
                const _CheckUpdateTile(),
                const Divider(),
                ListTile(
                  title: const Text('Документация'),
                  subtitle: const Text('Как пользоваться приложением'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/help'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ThemeModeTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme mode can be set via system settings or app settings
    return ListTile(
      leading: const Icon(Icons.palette),
      title: const Text('Тема оформления'),
      subtitle: const Text('Светлая / Тёмная / Системная'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Show theme selection dialog
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Выбор темы',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (ctx, anim1, anim2) => const Center(),
          transitionBuilder: (ctx, anim1, anim2, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: anim1, curve: Curves.easeOut),
              ),
              child: AlertDialog(
                title: const Text('Выберите тему'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: const Text('Светлая'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      title: const Text('Тёмная'),
                      onTap: () => Navigator.pop(context),
                    ),
                    ListTile(
                      title: const Text('Системная'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TwoFactorTile extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2FA status will be fetched from API in production
    final twoFactorEnabled = false;
    
    return ListTile(
      leading: const Icon(Icons.security),
      title: const Text('Двухфакторная аутентификация'),
      subtitle: const Text('Дополнительная защита аккаунта'),
      trailing: Switch(
        value: twoFactorEnabled,
        onChanged: (value) async {
          if (value) {
            // Enable 2FA
            final enabled = await _showEnable2FADialog(context, ref);
            if (context.mounted) {
              // Update UI
            }
          } else {
            // Disable 2FA
            await _showDisable2FADialog(context, ref);
          }
        },
      ),
    );
  }

  Future<bool> _showEnable2FADialog(BuildContext context, WidgetRef ref) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => const _Enable2FADialog(),
        ) ??
        false;
  }

  Future<void> _showDisable2FADialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Отключить 2FA?'),
            content: const Text('Это снизит безопасность вашего аккаунта'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Отключить'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmed) {
      try {
        final apiClient = ref.read(apiClientProvider);
        await apiClient.disableTwoFactor();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('2FA отключена')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(friendlyErrorMessage(e))),
          );
        }
      }
    }
  }
}

class _BiometricLoginTile extends StatefulWidget {
  const _BiometricLoginTile();

  @override
  State<_BiometricLoginTile> createState() => _BiometricLoginTileState();
}

class _BiometricLoginTileState extends State<_BiometricLoginTile> {
  final _biometricService = BiometricService();
  final _localStorage = LocalStorage();
  bool _isSupported = false;
  bool _isEnabled = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supported = await _biometricService.isDeviceSupported();
    final enabled = await _localStorage.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isSupported = supported;
        _isEnabled = enabled;
        _isChecking = false;
      });
    }
  }

  Future<void> _onChanged(bool value) async {
    if (value) {
      final confirmed = await _biometricService.authenticate(
        reason: 'Подтвердите, чтобы включить вход по отпечатку',
      );
      if (!confirmed) return;
    }
    await _localStorage.setBiometricEnabled(value);
    if (mounted) {
      setState(() => _isEnabled = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_biometricService.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    if (_isChecking) {
      return const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Вход по отпечатку'),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (!_isSupported) {
      return const ListTile(
        leading: Icon(Icons.fingerprint),
        title: Text('Вход по отпечатку'),
        subtitle: Text('На этом устройстве биометрия недоступна'),
        enabled: false,
      );
    }

    return ListTile(
      leading: const Icon(Icons.fingerprint),
      title: const Text('Вход по отпечатку'),
      subtitle: const Text('Быстрый вход без ввода пароля'),
      trailing: Switch(
        value: _isEnabled,
        onChanged: _onChanged,
      ),
    );
  }
}

class _VersionTile extends StatefulWidget {
  const _VersionTile();

  @override
  State<_VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<_VersionTile> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() => _version = info.version);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Версия'),
      subtitle: Text(_version.isEmpty ? '...' : _version),
    );
  }
}

class _CheckUpdateTile extends ConsumerStatefulWidget {
  const _CheckUpdateTile();

  @override
  ConsumerState<_CheckUpdateTile> createState() => _CheckUpdateTileState();
}

class _CheckUpdateTileState extends ConsumerState<_CheckUpdateTile> {
  bool _isChecking = false;

  @override
  Widget build(BuildContext context) {
    final updateService = ref.watch(updateServiceProvider);
    if (!updateService.isSupportedPlatform) {
      return const SizedBox.shrink();
    }

    return ListTile(
      leading: const Icon(Icons.system_update),
      title: const Text('Проверить обновления'),
      trailing: _isChecking
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isChecking
          ? null
          : () async {
              setState(() => _isChecking = true);
              await checkForUpdateAndPrompt(context, ref, silent: false);
              if (mounted) {
                setState(() => _isChecking = false);
              }
            },
    );
  }
}

class _Enable2FADialog extends ConsumerStatefulWidget {
  const _Enable2FADialog();

  @override
  ConsumerState<_Enable2FADialog> createState() => _Enable2FADialogState();
}

class _Enable2FADialogState extends ConsumerState<_Enable2FADialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _qrCodeUrl;

  Future<void> _enable2FA() async {
    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final result = await apiClient.enableTwoFactor();
      
      setState(() {
        _qrCodeUrl = result['qrCode'];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.verifyTwoFactor(_codeController.text.trim());
      
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA включена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Включить 2FA'),
      content: _qrCodeUrl == null
          ? _isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code, size: 64),
                    const SizedBox(height: 16),
                    const Text(
                      'Нажмите "Включить" для генерации QR-кода',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Отсканируйте QR-код в вашем приложении-аутентификаторе'),
              const SizedBox(height: 16),
              // QR code display
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.qr_code, size: 100),
                ),
              ),
              const SizedBox(height: 16),
                Form(
                  key: _formKey,
                  child: TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: 'Код подтверждения',
                      prefixIcon: Icon(Icons.security),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Введите код';
                      }
                      if (value.length != 6) {
                        return 'Код должен быть 6 цифр';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: _qrCodeUrl == null ? _enable2FA : _verifyCode,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(_qrCodeUrl == null ? 'Включить' : 'Подтвердить'),
        ),
      ],
    );
  }
}

class _ChangePasswordTile extends StatelessWidget {
  const _ChangePasswordTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.lock_outline),
      title: const Text('Сменить пароль'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // Show password change dialog
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Смена пароля'),
            content: const Text('Функция смены пароля будет реализована в следующей версии'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
  }
}
