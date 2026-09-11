import 'dart:io';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:notebook_app/core/network/api_client.dart';

class UpdateInfo {
  final String apkUrl;
  final String version;
  UpdateInfo({required this.apkUrl, required this.version});
}

/// Проверка и установка обновлений APK поверх текущей версии.
/// Работает только на Android — на других платформах checkForUpdate
/// всегда возвращает null.
class UpdateService {
  final ApiClient _apiClient;
  UpdateService(this._apiClient);

  bool get isSupportedPlatform => Platform.isAndroid;

  /// Сравнивает версию из /app/download/info с версией установленного
  /// приложения. Возвращает данные об обновлении, если на сервере версия
  /// новее, иначе null.
  Future<UpdateInfo?> checkForUpdate() async {
    if (!isSupportedPlatform) return null;

    final info = await _apiClient.getDownloadInfo();
    final serverVersion = info['version'] as String;
    final apkUrl = info['apkUrl'] as String;

    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    if (_isNewer(serverVersion, currentVersion)) {
      return UpdateInfo(apkUrl: apkUrl, version: serverVersion);
    }
    return null;
  }

  /// Скачивает APK и открывает системный установщик Android.
  /// Так как applicationId и подпись не меняются, система ставит его
  /// как обновление текущего приложения, а не отдельное новое —
  /// все данные (сохранённая сессия, настройки) сохраняются.
  Future<void> downloadAndInstall(
    String apkUrl, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/notebook-app-update.apk';

    final dio = Dio();
    await dio.download(
      apkUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total > 0 && onProgress != null) {
          onProgress(received / total);
        }
      },
    );

    await OpenFilex.open(filePath);
  }

  bool _isNewer(String serverVersion, String currentVersion) {
    final server = _parseVersion(serverVersion);
    final current = _parseVersion(currentVersion);
    for (var i = 0; i < 3; i++) {
      if (server[i] != current[i]) return server[i] > current[i];
    }
    return false;
  }

  List<int> _parseVersion(String version) {
    final parts = version.split('.');
    return List.generate(3, (i) {
      if (i >= parts.length) return 0;
      return int.tryParse(parts[i]) ?? 0;
    });
  }
}
