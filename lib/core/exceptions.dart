/// Base class for all HTTP exceptions that can be rendered as JSON responses.
class HttpException implements Exception {
  /// Creates a new [HttpException] with the given [statusCode] and [message].
  HttpException(this.statusCode, this.message, [this.details]);

  /// The HTTP status code (e.g., 404, 500).
  final int statusCode;

  /// A human-readable error message.
  final String message;

  /// Optional structured error details (e.g., validation errors).
  final Map<String, dynamic>? details;

  /// Converts the exception to a JSON-compatible map.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'message': message,
        if (details != null) 'errors': details,
      };

  @override
  String toString() => 'HttpException($statusCode): $message';
}

/// Thrown when request data fails validation (422).
class ValidationException extends HttpException {
  /// Creates a new [ValidationException] with the given [errors].
  ValidationException(Map<String, dynamic> errors) : super(422, 'The given data was invalid.', errors);
}

/// Thrown when the request is malformed (400).
class BadRequestException extends HttpException {
  /// Creates a new [BadRequestException].
  BadRequestException([String message = 'Bad Request']) : super(400, message);
}

/// Thrown when authentication is required but missing or invalid (401).
class UnauthorizedException extends HttpException {
  /// Creates a new [UnauthorizedException].
  UnauthorizedException([String message = 'Unauthorized']) : super(401, message);
}

/// Thrown when the authenticated user lacks permission (403).
class ForbiddenException extends HttpException {
  /// Creates a new [ForbiddenException].
  ForbiddenException([String message = 'Forbidden']) : super(403, message);
}

/// Thrown when a resource is not found (404).
class NotFoundException extends HttpException {
  /// Creates a new [NotFoundException].
  NotFoundException([String message = 'Resource not found']) : super(404, message);
}

/// Thrown when the HTTP method is not allowed for the endpoint (405).
class MethodNotAllowedException extends HttpException {
  /// Creates a new [MethodNotAllowedException].
  MethodNotAllowedException([String message = 'Method Not Allowed']) : super(405, message);
}

/// Thrown when a conflict occurs during state mutation (409).
class ConflictException extends HttpException {
  /// Creates a new [ConflictException].
  ConflictException([String message = 'Conflict detected']) : super(409, message);
}

/// Thrown when the rate limit is exceeded (429).
class TooManyRequestsException extends HttpException {
  /// Creates a new [TooManyRequestsException].
  TooManyRequestsException([String message = 'Too Many Requests']) : super(429, message);
}

/// Thrown when an unhandled server error occurs (500).
class InternalServerErrorException extends HttpException {
  /// Creates a new [InternalServerErrorException].
  InternalServerErrorException([String message = 'Internal Server Error']) : super(500, message);
}

/// Thrown when the server is temporarily unable to handle requests (503).
class ServiceUnavailableException extends HttpException {
  /// Creates a new [ServiceUnavailableException].
  ServiceUnavailableException([String message = 'Service Unavailable']) : super(503, message);
}
