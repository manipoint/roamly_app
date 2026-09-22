import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';

final assistantReadinessProvider = StreamProvider.autoDispose<bool>((ref) {
  final repository = ref.watch(assistantRepositoryProvider);
  return Stream<bool>.multi((controller) {
    final readinessSubscription = repository.readinessChanges.distinct().listen(
      controller.add,
      onError: controller.addError,
    );
    controller.add(repository.isReady);
    try {
      repository.connect();
    } catch (error, stackTrace) {
      controller.addError(error, stackTrace);
      controller.close();
    }
    controller.onCancel = () async {
      await readinessSubscription.cancel();
      await repository.disconnect();
    };
  });
});
