class HttpException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  HttpException(this.statusCode, this.message, [this.details]);

  Map<String, dynamic> toJson() => {
        'message': message,
        if (details != null) 'errors': details,
      };

  @override
  String toString() => 'HttpException($statusCode): $message';
}

class ValidationException extends HttpException {
  ValidationException(Map<String, dynamic> errors) 
    : super(422, 'The given data was invalid.', errors);
}

class BadRequestException extends HttpException {
  BadRequestException([String message = 'Bad Request']) : super(400, message);
}

class UnauthorizedException extends HttpException {
  UnauthorizedException([String message = 'Unauthorized']) : super(401, message);
}

class ForbiddenException extends HttpException {
  ForbiddenException([String message = 'Forbidden']) : super(403, message);
}

class NotFoundException extends HttpException {
  NotFoundException([String message = 'Resource not found']) : super(404, message);
}

class MethodNotAllowedException extends HttpException {
  MethodNotAllowedException([String message = 'Method Not Allowed']) : super(405, message);
}

class ConflictException extends HttpException {
  ConflictException([String message = 'Conflict detected']) : super(409, message);
}

class TooManyRequestsException extends HttpException {
  TooManyRequestsException([String message = 'Too Many Requests']) : super(429, message);
}

class InternalServerErrorException extends HttpException {
  InternalServerErrorException([String message = 'Internal Server Error']) : super(500, message);
}

class ServiceUnavailableException extends HttpException {
  ServiceUnavailableException([String message = 'Service Unavailable']) : super(503, message);
}
