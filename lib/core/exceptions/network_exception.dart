// lib/core/exceptions/network_exception.dart

class NetworkException implements Exception {
  final String message;
  final NetworkExceptionType type;

  NetworkException(this.message, {this.type = NetworkExceptionType.unknown});

  @override
  String toString() => message;
}

enum NetworkExceptionType { noConnection, timeout, serverError, unknown }
