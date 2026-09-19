import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';

/// Domain-facing access point for the realtime travel assistant.
///
/// Transport details such as WebSocket frames, heartbeat events, JSON models,
/// reconnect generations, and protocol configuration remain in the data layer.
abstract interface class AssistantRepository {
  Stream<AssistantEvent> get events;
  Stream<bool> get readinessChanges;
  bool get isReady;
  void connect();
  Future<void> disconnect();
  Future<void> sendRequest(AssistantRequest request);
  Future<void> dispose();
}
