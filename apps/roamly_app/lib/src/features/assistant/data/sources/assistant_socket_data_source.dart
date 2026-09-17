import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ping_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../models/connection_ready_event_model.dart';

abstract interface class AssistantSocketDataSource {
  Stream<AssistantIncomingEventModel> get events;
  bool get isReady;
  Stream<bool> get readinessChanges;
  ConnectionReadyEventModel? get readyConfiguration;

  WebSocketStatusSnapshot get status;
  Stream<WebSocketStatusSnapshot> get socketStates;

  void connect();
  void reportHeartbeatTimeout();

  Future<void> disconnect();
  Future<void> sendTravelRequest(TravelRequestEventModel request);
  Future<void> sendPing(ConnectionPingEventModel ping);
  Future<void> dispose();
}
