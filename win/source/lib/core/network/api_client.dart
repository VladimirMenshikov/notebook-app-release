import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late Dio _dio;
  final _storage = const FlutterSecureStorage();
  String? _accessToken;
  String? _refreshToken;
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _apiBaseUrlKey = 'api_base_url';
  
  String get apiBaseUrl => _dio.options.baseUrl;

  /// Есть ли сохранённая сессия (refresh-токен), с которой можно попробовать
  /// продолжить работу без повторного ввода пароля.
  bool get hasStoredSession => _refreshToken != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString(_apiBaseUrlKey) ?? 'https://nb.test-zc.ru/api';
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      contentType: 'application/json',
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ));

    // Add interceptors
    _dio.interceptors.add(_authInterceptor());
    _dio.interceptors.add(_errorInterceptor());
    
    // Load tokens. На Android ключ шифрования Android Keystore иногда
    // становится недействителен для уже сохранённых значений (например,
    // после сброса данных приложения системой) — чтение тогда падает с
    // PlatformException/BadPaddingException. В этом случае просто считаем,
    // что сохранённой сессии нет, вместо падения всего приложения на старте.
    try {
      _accessToken = await _storage.read(key: _accessTokenKey);
      _refreshToken = await _storage.read(key: _refreshTokenKey);
    } catch (_) {
      _accessToken = null;
      _refreshToken = null;
      try {
        await _storage.deleteAll();
      } catch (_) {
        // Если очистка тоже не удалась — ничего страшного, продолжаем
        // без сохранённой сессии.
      }
    }

    if (_accessToken != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
    }
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token if available
        if (_accessToken != null && 
            !options.path.contains('/auth/login') &&
            !options.path.contains('/auth/register-email') &&
            !options.path.contains('/auth/verify-email')) {
          options.headers['Authorization'] = 'Bearer $_accessToken';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        // Handle 401 - token expired
        if (error.response?.statusCode == 401) {
          try {
            await _performTokenRefresh();
            // Retry the original request
            final retryResponse = await _dio.request(
              error.requestOptions.path,
              options: Options(
                method: error.requestOptions.method,
                headers: {
                  'Authorization': 'Bearer $_accessToken',
                },
              ),
              data: error.requestOptions.data,
              queryParameters: error.requestOptions.queryParameters,
            );
            return handler.resolve(retryResponse);
          } catch (e) {
            // Refresh failed, logout
            await _logout();
            return handler.reject(error);
          }
        }
        return handler.next(error);
      },
    );
  }

  Interceptor _errorInterceptor() {
    return InterceptorsWrapper(
      onError: (error, handler) {
        // Error handling is done at the screen level
        // Users see appropriate error messages
        print('API Error: ${error.message}');
        return handler.next(error);
      },
    );
  }

  Future<void> _performTokenRefresh() async {
    if (_refreshToken == null) {
      await _logout();
      return;
    }

    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refreshToken': _refreshToken,
      });

      if (response.statusCode == 200) {
        final data = response.data;
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        
        await _storage.write(key: _accessTokenKey, value: _accessToken);
        await _storage.write(key: _refreshTokenKey, value: _refreshToken);
        
        _dio.options.headers['Authorization'] = 'Bearer $_accessToken';
      }
    } catch (e) {
      await _logout();
      rethrow;
    }
  }

  Future<void> _logout() async {
    _accessToken = null;
    _refreshToken = null;
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  // Auth methods
  Future<Map<String, dynamic>> registerEmail(String email, String password) async {
    final response = await _dio.post('/auth/register-email', data: {
      'email': email,
      'password': password,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> verifyEmail(String token, String name, {String? avatarName}) async {
    final response = await _dio.post('/auth/verify-email', data: {
      'token': token,
      'name': name,
      if (avatarName != null) 'avatarName': avatarName,
    });
    
    // Save tokens
    _accessToken = response.data['accessToken'];
    _refreshToken = response.data['refreshToken'];
    await _storage.write(key: _accessTokenKey, value: _accessToken);
    await _storage.write(key: _refreshTokenKey, value: _refreshToken);
    
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    
    // Save tokens
    _accessToken = response.data['accessToken'];
    _refreshToken = response.data['refreshToken'];
    await _storage.write(key: _accessTokenKey, value: _accessToken);
    await _storage.write(key: _refreshTokenKey, value: _refreshToken);
    
    return response.data;
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
    await _logout();
  }

  // Notes methods
  Future<Map<String, dynamic>> getNotes({
    int page = 1,
    int limit = 50,
    String? groupId,
    String? search,
  }) async {
    final response = await _dio.get('/notes', queryParameters: {
      'page': page,
      'limit': limit,
      if (groupId != null) 'groupId': groupId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getNote(String id) async {
    final response = await _dio.get('/notes/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> createNote(Map<String, dynamic> data) async {
    final response = await _dio.post('/notes', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateNote(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/notes/$id', data: data);
    return response.data;
  }

  Future<void> deleteNote(String id) async {
    await _dio.delete('/notes/$id');
  }

  Future<Map<String, dynamic>> toggleNoteFavorite(String id) async {
    final response = await _dio.put('/notes/$id/favorite');
    return response.data;
  }

  // Tasks methods
  Future<Map<String, dynamic>> getTasks({
    int page = 1,
    int limit = 50,
    bool? isCompleted,
    String? priority,
    String? groupId,
    String? search,
  }) async {
    final response = await _dio.get('/tasks', queryParameters: {
      'page': page,
      'limit': limit,
      if (isCompleted != null) 'isCompleted': isCompleted,
      if (priority != null) 'priority': priority,
      if (groupId != null) 'groupId': groupId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createSubtask(
    String taskId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.post('/tasks/$taskId/subtasks', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    final response = await _dio.post('/tasks', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateTask(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/tasks/$id', data: data);
    return response.data;
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('/tasks/$id');
  }

  // Questions methods
  Future<Map<String, dynamic>> getQuestions({
    int page = 1,
    int limit = 50,
    bool? answered,
    String? groupId,
    String? search,
  }) async {
    final response = await _dio.get('/questions', queryParameters: {
      'page': page,
      'limit': limit,
      if (answered != null) 'answered': answered,
      if (groupId != null) 'groupId': groupId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createQuestion(Map<String, dynamic> data) async {
    final response = await _dio.post('/questions', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateQuestion(String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/questions/$id', data: data);
    return response.data;
  }

  Future<void> deleteQuestion(String id) async {
    await _dio.delete('/questions/$id');
  }

  // Wishes methods
  Future<Map<String, dynamic>> getWishes({
    int page = 1,
    int limit = 50,
    String? status,
    String? groupId,
    String? search,
  }) async {
    final response = await _dio.get('/wishes', queryParameters: {
      'page': page,
      'limit': limit,
      if (status != null) 'status': status,
      if (groupId != null) 'groupId': groupId,
      if (search != null && search.isNotEmpty) 'search': search,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> createWish(Map<String, dynamic> data) async {
    final response = await _dio.post('/wishes', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> updateWish(
    String id,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.put('/wishes/$id', data: data);
    return response.data;
  }

  Future<void> deleteWish(String id) async {
    await _dio.delete('/wishes/$id');
  }

  // Groups methods
  Future<List<dynamic>> getGroups() async {
    final response = await _dio.get('/groups');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createGroup(String name) async {
    final response = await _dio.post('/groups', data: {'name': name});
    return response.data;
  }

  Future<Map<String, dynamic>> getGroup(String id) async {
    final response = await _dio.get('/groups/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> renameGroup(String id, String name) async {
    final response = await _dio.put('/groups/$id', data: {'name': name});
    return response.data;
  }

  Future<void> deleteGroup(String id) async {
    await _dio.delete('/groups/$id');
  }

  Future<void> inviteToGroup(String groupId, String email) async {
    await _dio.post('/groups/$groupId/invitations', data: {'email': email});
  }

  Future<void> revokeInvitation(String groupId, String invId) async {
    await _dio.delete('/groups/$groupId/invitations/$invId');
  }

  Future<void> removeGroupMember(String groupId, String userId) async {
    await _dio.delete('/groups/$groupId/members/$userId');
  }

  Future<void> leaveGroup(String groupId) async {
    await _dio.post('/groups/$groupId/leave');
  }

  Future<List<dynamic>> getMyInvitations() async {
    final response = await _dio.get('/groups/invitations/mine');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> respondInvitation(
    String token, {
    required bool accept,
  }) async {
    final response = await _dio.post(
      '/groups/invitations/$token/${accept ? 'accept' : 'decline'}',
    );
    return response.data;
  }

  // User methods
  Future<Map<String, dynamic>> getProfile() async {
    final response = await _dio.get('/users/me');
    return response.data;
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put('/users/profile', data: data);
    return response.data;
  }

  // Avatars methods
  Future<List<dynamic>> getBuiltinAvatars() async {
    final response = await _dio.get('/avatars/builtin');
    return response.data;
  }

  // 2FA methods
  Future<Map<String, dynamic>> enableTwoFactor() async {
    final response = await _dio.post('/auth/two-factor/enable');
    return response.data;
  }

  Future<void> disableTwoFactor() async {
    await _dio.post('/auth/two-factor/disable');
  }

  Future<void> verifyTwoFactor(String token) async {
    await _dio.post('/auth/two-factor/verify', data: {'token': token});
  }

  // Download / QR methods
  Future<Map<String, dynamic>> getDownloadInfo() async {
    final response = await _dio.get('/app/download/info');
    return response.data;
  }

  Future<String> getQRCode() async {
    final response = await _dio.get(
      '/app/download/qr',
      options: Options(responseType: ResponseType.bytes),
    );
    return base64Encode(response.data);
  }
}
