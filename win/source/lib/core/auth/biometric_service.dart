import 'dart:io';
import 'package:local_auth/local_auth.dart';

/// Обёртка над local_auth для входа по отпечатку/лицу.
/// Функция ограничена Android — см. требование "в Android-версии".
class BiometricService {
  final _localAuth = LocalAuthentication();

  bool get isSupportedPlatform => Platform.isAndroid;

  /// Есть ли на устройстве датчик биометрии и настроен ли он (отпечаток/лицо).
  Future<bool> isDeviceSupported() async {
    if (!isSupportedPlatform) return false;
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final deviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && deviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Показывает системный диалог биометрии. Возвращает true при успехе.
  Future<bool> authenticate({required String reason}) async {
    if (!isSupportedPlatform) return false;
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
