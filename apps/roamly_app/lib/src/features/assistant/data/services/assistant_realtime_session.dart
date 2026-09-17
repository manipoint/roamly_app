import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';

abstract interface class AssistantRealtimeSession {
  Stream<AssistantIncomingEventModel> get events;
  bool get isReady;
  Stream<bool> get readinessChanges;
  void connect();
  Future<void> disconnect();
  Future<void> sendTravelRequest(TravelRequestEventModel request);
  Future<void> dispose();
}
