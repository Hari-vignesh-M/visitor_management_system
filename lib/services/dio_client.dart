import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants/end_points_constants.dart';
import 'exceptions/app_exception.dart';


class ApiClient {
  ApiClient._internal()
      : _dio = Dio(
          BaseOptions(
            baseUrl: EndPointConstants.baseUrl,
            connectTimeout: EndPointConstants.connectTimeout,
            receiveTimeout: EndPointConstants.receiveTimeout,
            contentType: Headers.jsonContentType,
            responseType: ResponseType.json,
          ),
        ) {
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  final Dio _dio;

  Future<dynamic> get(String path) => _request(() => _dio.get(path));

  Future<dynamic> post(String path, {Object? data}) =>
      _request(() => _dio.post(path, data: data));

  Future<dynamic> put(String path, {Object? data}) =>
      _request(() => _dio.put(path, data: data));

  Future<dynamic> delete(String path) => _request(() => _dio.delete(path));

  Future<dynamic> _request(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (_) {
      throw const BadResponseException();
    }
  }

  AppException _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const NetworkException('The request timed out. Please try again.');
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) return const NotFoundException();
        if (code != null && code >= 500) {
          return ServerException(
            'Server error ($code). Please try again later.',
            statusCode: code,
          );
        }
        return ServerException('Request failed ($code).', statusCode: code);
      case DioExceptionType.badCertificate:
        return const NetworkException('Secure connection failed.');
      case DioExceptionType.cancel:
        return const AppException('Request was cancelled.');
      case DioExceptionType.unknown:
        return const NetworkException();
    }
  }
}
