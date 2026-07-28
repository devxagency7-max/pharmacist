/// A friendly, typed error thrown by [ApiClient] for any non-2xx response.
///
/// [message] is taken from the backend's ApiResponse envelope ({success,
/// message, data, errors, errorCode}) when present, so UI code can display
/// it directly instead of a raw DioException.toString().
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final List<String>? errors;
  // Stable machine-readable error identifier (e.g. "CONVERSATION_CLOSED").
  // Always null except for specific documented cases — prefer this over
  // matching on `message` text, which is free-form and can be localized.
  final String? errorCode;

  ApiException(this.message, {this.statusCode, this.errors, this.errorCode});

  @override
  String toString() => message;
}
