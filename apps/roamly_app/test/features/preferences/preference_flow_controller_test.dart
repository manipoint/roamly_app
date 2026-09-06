import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/preferences/presentation/controllers/preference_flow_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
    addTearDown(container.dispose);
  });

  ProviderSubscription<PreferenceFlowStep> keepAlive() {
    final subscription = container.listen(
      preferenceFlowControllerProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    return subscription;
  }

  test('starts at travel style with stable metadata', () {
    keepAlive();
    final controller = container.read(
      preferenceFlowControllerProvider.notifier,
    );

    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.travelStyle,
    );
    expect(controller.currentIndex, 0);
    expect(controller.stepCount, PreferenceFlowStep.values.length);
    expect(controller.isFirstStep, isTrue);
    expect(controller.isLastStep, isFalse);
  });

  test('next moves forward and stops at the final step', () {
    keepAlive();
    final controller = container.read(
      preferenceFlowControllerProvider.notifier,
    );

    expect(controller.next(), isTrue);
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.interestsAndBudget,
    );
    expect(controller.next(), isTrue);
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.discoveryScope,
    );
    expect(controller.next(), isFalse);
  });

  test('previous moves backward and stops at the first step', () {
    keepAlive();
    final controller = container.read(preferenceFlowControllerProvider.notifier)
      ..goTo(PreferenceFlowStep.discoveryScope);

    expect(controller.previous(), isTrue);
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.interestsAndBudget,
    );
    expect(controller.previous(), isTrue);
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.travelStyle,
    );
    expect(controller.previous(), isFalse);
  });

  test('goTo and reset provide deterministic flow control', () {
    keepAlive();
    final controller = container.read(
      preferenceFlowControllerProvider.notifier,
    );

    controller.goTo(PreferenceFlowStep.interestsAndBudget);
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.interestsAndBudget,
    );
    controller.reset();
    expect(
      container.read(preferenceFlowControllerProvider),
      PreferenceFlowStep.travelStyle,
    );
  });
}
