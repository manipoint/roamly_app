abstract interface class ApiClient {
  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  });
  Future<Object?> post(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  });

  Future<Object?> put(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  });

  Future<Object?> patch(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  });

  Future<Object?> delete(
    String path, {
    Object? data,
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  });
}
