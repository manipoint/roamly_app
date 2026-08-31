import 'package:dio/dio.dart';
import 'package:roamly_core/roamly_core.dart';
import '../failures/dio_failure_mapper.dart';

/// Executes API operations and converts expected Dio errors into safe results.
abstract interface class ApiRequestExecutor {
  Future<Result<T>> execute<T>(Future<T> Function() request);
}

/// Default API request execution boundary.

final class DefaultApiRequestExecutor implements ApiRequestExecutor {
  const DefaultApiRequestExecutor({required this._failureMapper});

  final DioFailureMapper _failureMapper;
  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) async {
    try {
      final value = await request();
      return Success<T>(value);
    } on DioException catch (exception) {
      return FailureResult<T>(_failureMapper.map(exception));
    }
  }
}
