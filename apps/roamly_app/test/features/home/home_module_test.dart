import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/composition/home_module.dart';
import 'package:roamly_app/src/features/home/data/repositories/default_home_discovery_repository.dart';
import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_networking/roamly_networking.dart';

final class _ApiClient implements ApiClient {
  int calls = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    return super.noSuchMethod(invocation);
  }
}

final class _RequestExecutor implements ApiRequestExecutor {
  int calls = 0;

  @override
  Future<Result<T>> execute<T>(Future<T> Function() request) {
    calls++;
    throw UnsupportedError('No request is expected during composition.');
  }
}

void main() {
  test('creates the repository without performing network work', () {
    final client = _ApiClient();
    final executor = _RequestExecutor();

    final repository = HomeModule.create(
      authenticatedClient: client,
      requestExecutor: executor,
    );

    expect(repository, isA<DefaultHomeDiscoveryRepository>());
    expect(client.calls, 0);
    expect(executor.calls, 0);
  });
}
