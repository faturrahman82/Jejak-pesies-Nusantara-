enum ApiFailureKind { network, timeout, httpStatus, invalidJson }

class ApiException implements Exception {
  const ApiException(this.kind, this.message, {this.statusCode});

  final ApiFailureKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
