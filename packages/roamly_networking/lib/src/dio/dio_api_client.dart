import 'package:dio/dio.dart';
import 'package:roamly_networking/src/client/api_client.dart';

final class DioApiClient implements ApiClient {
  final Dio _dio;

  DioApiClient({required Dio dio}) : _dio = dio;
  @override
  Future<Object?> delete(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _request(
      method: 'DELETE',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _request(
      method: "GET",
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> patch(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _request(
      method: 'PATCH',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _request(
      method: 'POST',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  @override
  Future<Object?> put(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) {
    return _request(
      method: 'PUT',
      path: path,
      data: data,
      queryParameters: queryParameters,
      headers: headers,
    );
  }

  Future<Object?> _request({
    required String method,
    required String path,
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) async {
    final response = await _dio.request<Object?>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: Options(method: method, headers: headers),
    );

    return response.data;
  }
}
