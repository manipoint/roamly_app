import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';

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
