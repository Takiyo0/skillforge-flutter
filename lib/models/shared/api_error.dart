class ApiError implements Exception {
  ApiError({required this.message, this.statusCode, this.timestamp});

  final String message;
  final int? statusCode;
  final String? timestamp;

  @override
  String toString() => 'ApiError(statusCode: $statusCode, message: $message)';
}
