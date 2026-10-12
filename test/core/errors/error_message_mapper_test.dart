import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pharmacist/core/errors/api_exception.dart';
import 'package:pharmacist/core/errors/error_message_mapper.dart';

DioException _dioWith(ApiException api) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  error: api,
);

void main() {
  group('mapErrorToMessage', () {
    test('maps Firebase invalid-credential to a wrong-password message', () {
      final message = mapErrorToMessage(
        FirebaseAuthException(code: 'invalid-credential'),
      );
      expect(message, contains('كلمة المرور غير صحيحة'));
    });

    test('maps duplicate National/Syndicate ID 409 to an Arabic message', () {
      final message = mapErrorToMessage(
        _dioWith(
          ApiException(
            'This National ID / Syndicate ID is already registered to another account.',
            statusCode: 409,
          ),
        ),
      );
      expect(message, contains('رقم النقابة'));
      expect(message, isNot(contains('DioException')));
    });

    test('passes through an Arabic backend message as is', () {
      final message = mapErrorToMessage(
        _dioWith(ApiException('الطلب غير موجود', statusCode: 404)),
      );
      expect(message, 'الطلب غير موجود');
    });

    test('falls back to a status-based message for unknown English errors', () {
      final message = mapErrorToMessage(
        _dioWith(ApiException('Boom', statusCode: 500)),
      );
      expect(message, contains('الخادم'));
    });

    test('maps timeouts and connection errors', () {
      final timeout = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.receiveTimeout,
      );
      final offline = DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionError,
      );
      expect(mapErrorToMessage(timeout), contains('مهلة'));
      expect(mapErrorToMessage(offline), contains('الإنترنت'));
    });

    test('returns a generic message for unknown errors', () {
      expect(mapErrorToMessage(StateError('x')), contains('غير متوقع'));
    });
  });
}
