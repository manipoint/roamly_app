import '../failures/app_failure.dart';

/// Represents either a successful value or an expected application failure.
sealed class Result<T> {
  const Result();

  /// Whether this result contains a successful value.
  bool get isSuccess => this is Success<T>;

  /// Whether this result contains an application failure.
  bool get isFailure => this is FailureResult<T>;

  /// Converts this result into [R] by handling both possible states.
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  });

  /// Transforms a successful value while preserving an existing failure.
  Result<R> map<R>(R Function(T value) transform);
}

/// A successful [Result] containing a value of type [T].
final class Success<T> extends Result<T> {
  const Success(this.value);

  /// The successful operation value.
  final T value;

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    return onSuccess(value);
  }

  @override
  Result<R> map<R>(R Function(T value) transform) {
    return Success<R>(transform(value));
  }
}

/// A failed [Result] containing a safe application failure.
final class FailureResult<T> extends Result<T> {
  /// The expected application failure.
  final AppFailure failure;

  const FailureResult(this.failure);

  @override
  R fold<R>({
    required R Function(T value) onSuccess,
    required R Function(AppFailure failure) onFailure,
  }) {
    return onFailure(failure);
  }

  @override
  Result<R> map<R>(R Function(T value) transform) {
    return FailureResult<R>(failure);
  }
}
