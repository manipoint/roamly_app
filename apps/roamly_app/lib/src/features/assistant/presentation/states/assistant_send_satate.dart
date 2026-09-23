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
