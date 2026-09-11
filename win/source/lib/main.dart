import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notebook_app/core/theme/app_theme.dart';
import 'package:notebook_app/navigation/app_router.dart';
import 'package:notebook_app/core/network/api_client.dart';
import 'package:notebook_app/core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize SharedPreferences
    await SharedPreferences.getInstance();

    // Initialize local storage
    final localStorage = LocalStorage();

    // Initialize API client
    final apiClient = ApiClient();
    await apiClient.init();

    runApp(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
        ],
        child: NotebookApp(),
      ),
    );
  } catch (error, stackTrace) {
    // Не даём приложению зависнуть на пустом чёрном экране, если что-то
    // упало ещё до первого runApp — показываем причину вместо этого.
    debugPrint('Fatal startup error: $error\n$stackTrace');
    runApp(_StartupErrorApp(error: error));
  }
}

class _StartupErrorApp extends StatelessWidget {
  final Object error;
  const _StartupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Не удалось запустить приложение',
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text('$error', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NotebookApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Notebook App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
