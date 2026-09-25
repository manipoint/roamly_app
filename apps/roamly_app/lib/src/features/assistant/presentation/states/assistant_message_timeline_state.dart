import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';

enum AssistantTimelineFailureSource { recentMessages, pagination }

final class AssistantMessageTimelineState {
  final List<AssistantMessage> messages;
  final bool isInitialLoading;
  final bool isLoadingOlder;
  final bool hasMoreOlder;
  final AssistantTimelineFailureSource? failureSource;
  final Object? failure;
  final StackTrace? failureStackTrace;

  AssistantMessageTimelineState({
    List<AssistantMessage> messages = const [],
    this.isInitialLoading = true,
    this.isLoadingOlder = false,
    this.hasMoreOlder = false,
    this.failureSource,
    this.failure,
    this.failureStackTrace,
  }) : messages = List.unmodifiable(messages);
  bool get hasFailure => failure != null;
  bool get isAwaitingAssistantResponse {
    for (final message in messages.reversed) {
      if (message.author != AssistantMessageAuthor.user) {
        continue;
      }
      final isUnresolved = switch (message.deliveryState) {
        AssistantMessageDeliveryState.pending ||
        AssistantMessageDeliveryState.sent ||
        AssistantMessageDeliveryState.processing => true,
        AssistantMessageDeliveryState.completed ||
        AssistantMessageDeliveryState.failed => false,
      };
      if (isUnresolved) {
        return true;
      }
    }
    return false;
  }

  AssistantMessageTimelineState copyWith({
    List<AssistantMessage>? messages,
    bool? isInitialLoading,
    bool? isLoadingOlder,
    bool? hasMoreOlder,
    Object? failure,
    AssistantTimelineFailureSource? failureSource,
    StackTrace? failureStackTrace,
    bool clearFailure = false,
  }) {
    return AssistantMessageTimelineState(
      messages: messages ?? this.messages,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      hasMoreOlder: hasMoreOlder ?? this.hasMoreOlder,
      failureSource: clearFailure ? null : failureSource ?? this.failureSource,
      failure: clearFailure ? null : failure ?? this.failure,
      failureStackTrace: clearFailure
          ? null
          : failureStackTrace ?? this.failureStackTrace,
    );
  }
}
