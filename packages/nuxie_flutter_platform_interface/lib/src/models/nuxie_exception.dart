class NuxieException implements Exception {
  const NuxieException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final String? details;

  @override
  String toString() =>
      'NuxieException(code: $code, message: $message, details: $details)';
}
