import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/api_constants.dart';
import '../errors/api_exception.dart';

/// Centralized Dio client for the whole app.
///
/// - Attaches the current Firebase ID token as a Bearer header on every
///   request.
/// - On a 401, force-refreshes the Firebase ID token and retries the
///   request once before giving up (per the backend's documented contract).
/// - Unwraps the backend's `ApiResponse<T>` envelope on error responses and
///   throws an [ApiException] carrying the real `message`/`errors`, so
///   callers never have to parse a raw [DioException] themselves.
class ApiClient {
  final Dio dio;
  final FirebaseAuth _firebaseAuth;

  ApiClient(this._firebaseAuth)
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
        ),
      ) {
    dio.interceptors.add(
      QueuedInterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _firebaseAuth.currentUser?.getIdToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final statusCode = error.response?.statusCode;

          if (statusCode == 401 &&
              error.requestOptions.extra['retried'] != true) {
            final refreshedToken = await _firebaseAuth.currentUser?.getIdToken(
              true,
            );
            if (refreshedToken != null) {
              try {
                final retryOptions = error.requestOptions;
                retryOptions.extra['retried'] = true;
                retryOptions.headers['Authorization'] =
                    'Bearer $refreshedToken';
                final response = await dio.fetch(retryOptions);
                handler.resolve(response);
                return;
              } catch (_) {
                // Fall through to the normal error mapping below.
              }
            }
          }

          handler.next(_mapError(error));
        },
      ),
    );
  }

  DioException _mapError(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      final errors = (data['errors'] as List?)
          ?.map((e) => e.toString())
          .toList();
      return error.copyWith(
        error: ApiException(
          message ?? 'حدث خطأ غير متوقع',
          statusCode: error.response?.statusCode,
          errors: errors,
          errorCode: data['errorCode'] as String?,
        ),
      );
    }
    return error.copyWith(
      error: ApiException(
        _fallbackMessage(error),
        statusCode: error.response?.statusCode,
      ),
    );
  }

  String _fallbackMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'انتهت مهلة الاتصال بالخادم، حاول مرة أخرى.';
      case DioExceptionType.connectionError:
        return 'تعذر الاتصال بالإنترنت، تحقق من اتصالك وحاول مرة أخرى.';
      default:
        return 'حدث خطأ غير متوقع، حاول مرة أخرى.';
    }
  }
}

/// Unwraps the backend's `{success, message, data, errors}` envelope and
/// returns just the `data` payload, throwing [ApiException] if `success` is
/// false even on a 2xx response.
T unwrapApiResponse<T>(Response response, T Function(dynamic json) fromJson) {
  final body = response.data;
  if (body is Map<String, dynamic>) {
    final success = body['success'] as bool? ?? true;
    if (!success) {
      final errors = (body['errors'] as List?)
          ?.map((e) => e.toString())
          .toList();
      throw ApiException(
        body['message'] as String? ?? 'حدث خطأ غير متوقع',
        statusCode: response.statusCode,
        errors: errors,
        errorCode: body['errorCode'] as String?,
      );
    }
    return fromJson(body['data']);
  }
  return fromJson(body);
}
