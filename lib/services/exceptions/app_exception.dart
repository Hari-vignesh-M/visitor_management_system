class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException(this.message, {this.statusCode});

  @override
  String toString() => message;
}


class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Unable to reach the server. Check your internet connection.',
  ]);
}


class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Record not found.'])
      : super(statusCode: 404);
}


class ServerException extends AppException {
  const ServerException(super.message, {super.statusCode});
}

class BadResponseException extends AppException {
  const BadResponseException([
    super.message = 'Received an invalid response from the server.',
  ]);
}
