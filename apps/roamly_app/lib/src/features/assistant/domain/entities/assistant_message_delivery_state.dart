enum AssistantMessageDeliveryState {
  /// Stored locally but not yet written to the realtime connection.
  pending,

  /// Accepted by the backend.
  sent,

  /// The backend is generating the assistant response.
  processing,

  /// The complete response has been received and stored.
  completed,

  /// The request was rejected or response generation failed.
  failed,
}
