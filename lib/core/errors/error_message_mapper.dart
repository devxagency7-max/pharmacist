import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'api_exception.dart';

/// Turns any thrown error into a short, user-friendly Arabic message that
/// says what went wrong and, where possible, what the user can do about it.
///
/// UI code should show this instead of `$e`, which leaks raw exception text
/// (e.g. the full DioException description).
String mapErrorToMessage(Object error) {
  if (error is FirebaseAuthException) return _firebaseMessage(error);

  if (error is DioException) {
    final inner = error.error;
    if (inner is ApiException) return _apiMessage(inner);
    return _dioMessage(error);
  }

  if (error is ApiException) return _apiMessage(error);
  if (error is SocketException) return _noConnection;
  if (error is TimeoutException) return _timeout;

  return 'حدث خطأ غير متوقع، حاول مرة أخرى.';
}

/// Returns the backend's [ApiException] whether it was thrown directly or
/// wrapped by [ApiClient] inside a [DioException]; null for anything else.
/// Use this (not `e is ApiException`) to branch on status/error codes.
ApiException? asApiException(Object error) {
  if (error is ApiException) return error;
  if (error is DioException && error.error is ApiException) {
    return error.error as ApiException;
  }
  return null;
}

const _noConnection ='تعذر الاتصال بالإنترنت، تحقق من اتصالك وحاول مرة أخرى.';
const _timeout = 'انتهت مهلة الاتصال بالخادم، حاول مرة أخرى.';

String _firebaseMessage(FirebaseAuthException e) {
  switch (e.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'invalid-login-credentials':
      return 'البريد الإلكتروني أو كلمة المرور غير صحيحة.\n'
          'لو سجّلت بنفس البريد قبل كده، اكتب نفس كلمة المرور اللي استخدمتها أول مرة.';
    case 'email-already-in-use':
      return 'هذا البريد الإلكتروني مسجل بالفعل، سجّل الدخول بدلاً من إنشاء حساب جديد.';
    case 'invalid-email':
      return 'صيغة البريد الإلكتروني غير صحيحة.';
    case 'weak-password':
      return 'كلمة المرور ضعيفة، استخدم 6 أحرف على الأقل.';
    case 'user-not-found':
      return 'لا يوجد حساب بهذا البريد الإلكتروني.';
    case 'user-disabled':
      return 'تم إيقاف هذا الحساب، تواصل مع الدعم.';
    case 'too-many-requests':
      return 'محاولات كثيرة جداً، انتظر قليلاً ثم حاول مرة أخرى.';
    case 'network-request-failed':
      return _noConnection;
    default:
      return 'تعذر تسجيل الدخول، حاول مرة أخرى.';
  }
}

String _apiMessage(ApiException e) {
  final backendMessage = e.message;
  final lower = backendMessage.toLowerCase();

  // Known backend business rules (messages come back in English).
  if (lower.contains('national id') || lower.contains('syndicate id')) {
    return 'رقم النقابة / الهوية ده مسجل على حساب تاني بالفعل.\n'
        'تأكد من الرقم، أو استخدم رقم مختلف.';
  }

  // The backend sometimes already sends Arabic — show it as is.
  if (_containsArabic(backendMessage)) return backendMessage;

  return switch (e.statusCode) {
    400 || 422 => 'البيانات المدخلة غير صحيحة، راجعها وحاول مرة أخرى.',
    401 => 'انتهت الجلسة، سجّل الدخول مرة أخرى.',
    403 => 'ليس لديك صلاحية لتنفيذ هذا الإجراء.',
    404 => 'العنصر المطلوب غير موجود.',
    409 => 'هذه البيانات مسجلة بالفعل، راجعها وحاول مرة أخرى.',
    int code when code >= 500 => 'حدث خطأ في الخادم، حاول مرة أخرى بعد قليل.',
    _ => 'حدث خطأ غير متوقع، حاول مرة أخرى.',
  };
}

String _dioMessage(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return _timeout;
    case DioExceptionType.connectionError:
      return _noConnection;
    default:
      return 'حدث خطأ غير متوقع، حاول مرة أخرى.';
  }
}

bool _containsArabic(String text) => RegExp(r'[؀-ۿ]').hasMatch(text);
