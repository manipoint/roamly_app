import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Ordered screens in the Phase-1 preference onboarding flow.
enum PreferenceFlowStep { travelStyle, interestsAndBudget, discoveryScope }

final preferenceFlowControllerProvider =
    NotifierProvider.autoDispose<PreferenceFlowController, PreferenceFlowStep>(
      PreferenceFlowController.new,
    );

final class PreferenceFlowController extends Notifier<PreferenceFlowStep> {
  @override
  PreferenceFlowStep build() => PreferenceFlowStep.travelStyle;

  int get currentIndex => state.index;

  int get stepCount => PreferenceFlowStep.values.length;

  bool get isFirstStep => state == PreferenceFlowStep.travelStyle;

  bool get isLastStep => state == PreferenceFlowStep.discoveryScope;

  bool next() {
    if (isLastStep) {
      return false;
    }

    state = PreferenceFlowStep.values[state.index + 1];
    return true;
  }

  bool previous() {
    if (isFirstStep) {
      return false;
    }

    state = PreferenceFlowStep.values[state.index - 1];
    return true;
  }

  void goTo(PreferenceFlowStep step) {
    state = step;
  }

  void reset() {
    state = PreferenceFlowStep.travelStyle;
  }
}
