import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_request_factory_provider.dart';

final assistantSendControllerProvider =
    NotifierProvider.autoDispose<AssistantSendController, AssistantSendState>(
      AssistantSendController.new,
    );

enum AssistantSendStatus { idle, sending, failed }

final class AssistantSendState {
  final AssistantSendStatus status;
  final Object? failure;
  bool get isSending => status == AssistantSendStatus.sending;
  bool get hasFailure => status == AssistantSendStatus.failed;
  const AssistantSendState._({required this.status, this.failure});
  const AssistantSendState.idle() : this._(status: AssistantSendStatus.idle);
  const AssistantSendState.sending()
    : this._(status: AssistantSendStatus.sending);
  const AssistantSendState.failed(Object failure)
    : this._(status: AssistantSendStatus.failed, failure: failure);
}

final class AssistantSendController extends Notifier<AssistantSendState> {
  @override
  AssistantSendState build() {
    return const AssistantSendState.idle();
  }

  /// Creates and submits one Assistant request.
  ///
  /// Returns the submitted request when the repository accepts it.
  /// Returns `null` when another submission is already running or submission
  /// fails.
  ///
  /// The repository remains responsible for local persistence and pending
  /// request replay. This controller intentionally does not require an active
  /// WebSocket before submitting.
  Future<AssistantRequest?> sendMessage({
    required String message,
    AssistantConversation? conversation,
    String locale = 'en',
    String? tripId,
  }) async {
    if (state.isSending) {
      return null;
    }
    state = const AssistantSendState.sending();
    try {
      final request = ref
          .read(assistantRequestFactoryProvider)
          .create(
            conversationLocalId: conversation?.localId,
            conversationId: conversation?.remoteId,
            locale: locale,
            tripId: tripId,
            message: message,
          );
      await ref.read(assistantRepositoryProvider).sendRequest(request);
      if (ref.mounted) {
        state = const AssistantSendState.idle();
      }
      return request;
    } catch (error) {
      if (ref.mounted) {
        state = AssistantSendState.failed(error);
      }
      return null;
    }
  }

  void clearFailure() {
    if (!state.isSending && state.hasFailure) {
      state = const AssistantSendState.idle();
    }
  }
}
