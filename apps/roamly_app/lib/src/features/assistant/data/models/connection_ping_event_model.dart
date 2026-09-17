final class ConnectionPingEventModel {
  ConnectionPingEventModel({required DateTime sentAt})
    : sentAt = sentAt.toUtc();

  final DateTime sentAt;

  Map<String, Object?> toJson() {
    return {
      'version': 1,
      'type': 'connection.ping',
      'sent_at': sentAt.toIso8601String(),
      'payload': <String, Object?>{},
    };
  }
}
