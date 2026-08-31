import 'package:dio/dio.dart';
import '../config/api_config.dart';

abstract final class DioFactory {
  static Dio create({required ApiConfig configuration}) {
    final options = BaseOptions(
      baseUrl: configuration.baseUri.toString(),
      connectTimeout: configuration.connectTimeout,
      receiveTimeout: configuration.receiveTimeout,
      sendTimeout: configuration.sendTimeout,
      responseType: ResponseType.json,
      headers: const {Headers.acceptHeader: Headers.jsonContentType},
    );
    return Dio(options);
  }
}
