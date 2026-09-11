import 'package:dio/dio.dart';

/// Превращает ошибку сети/сервера в понятное пользователю сообщение на русском.
String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Сервер не отвечает. Проверьте интернет-соединение и попробуйте ещё раз.';
      case DioExceptionType.connectionError:
        return 'Нет соединения с сервером. Проверьте интернет.';
      case DioExceptionType.badCertificate:
        return 'Проблема с сертификатом безопасности сервера.';
      case DioExceptionType.cancel:
        return 'Запрос отменён.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return _messageFromResponse(error.response) ??
            'Не удалось выполнить запрос. Попробуйте позже.';
      default:
        return 'Не удалось выполнить запрос. Попробуйте позже.';
    }
  }
  return 'Произошла непредвиденная ошибка. Попробуйте ещё раз.';
}

String? _messageFromResponse(Response? response) {
  final data = response?.data;
  String? serverMessage;
  if (data is Map && data['message'] != null) {
    final message = data['message'];
    serverMessage = message is List ? message.join(', ') : message.toString();
  }
  if (serverMessage == null) return null;
  return _translations[serverMessage] ?? serverMessage;
}

const _translations = <String, String>{
  'Email already registered': 'Пользователь с таким email уже зарегистрирован',
  'Invalid credentials': 'Неверный email или пароль',
  'Email not verified': 'Email не подтверждён. Проверьте почту.',
  'Invalid or expired verification token':
      'Неверный или истёкший код подтверждения',
  'User not found': 'Пользователь не найден',
  'Password must be at least 6 characters':
      'Пароль должен быть не короче 6 символов',
};
