class HttpException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? details;

  HttpException(this.statusCode, this.message, [this.details]);

  Map<String, dynamic> toJson() => {
        'message': message,
        if (details != null) 'errors': details, // Renamed to 'errors' for consistency with validation
      };

  @override
  String toString() => 'HttpException($statusCode): $message';
}

class ValidationException extends HttpException {
  ValidationException(Map<String, dynamic> errors) 
    : super(422, 'The given data was invalid.', errors);
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

class ConflictException extends HttpException {
  ConflictException([String message = 'Conflict detected']) : super(409, message);
}

class InternalServerErrorException extends HttpException {
  InternalServerErrorException([String message = 'Internal Server Error']) : super(500, message);
}
