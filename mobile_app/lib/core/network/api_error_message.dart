import 'package:dio/dio.dart';

/// Maps [DioException] and other errors to short, user-facing copy (no stack traces).
String userFacingApiMessage(Object error) {
  if (error is DioException) {
    final status = error.response?.statusCode;

    if (status == 401) {
      return 'Invalid email or password.';
    }
    if (status == 403) {
      final detail = _responseDetail(error);
      if (detail.toLowerCase().contains('deactivat')) {
        return 'This account has been deactivated.';
      }
      return 'Access denied. Please try again.';
    }
    if (status != null && status >= 500) {
      return 'Something went wrong on our side. Please try again later.';
    }
    if (status == 404) {
      return 'Service not found. Please try again later.';
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Request timed out. Check your connection and try again.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Check your network and try again.';
      case DioExceptionType.badCertificate:
        return 'Secure connection failed. Please try again later.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.unknown:
        if (error.error.toString().toLowerCase().contains('socket') ||
            error.error.toString().toLowerCase().contains('network')) {
          return 'No internet connection. Check your network and try again.';
        }
        break;
      case DioExceptionType.badResponse:
        break;
    }
  }

  return 'Something went wrong. Please try again.';
}

String _responseDetail(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['detail'] != null) {
    final d = data['detail'];
    if (d is String) return d;
  }
  return '';
}
