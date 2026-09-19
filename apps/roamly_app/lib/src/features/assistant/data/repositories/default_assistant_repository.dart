import 'package:roamly_app/src/features/assistant/data/mappers/assistant_event_model_mapper.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';

import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';

import '../../domain/repositories/assistant_repository.dart';
import '../models/travel_request_event_model.dart';
import '../services/assistant_realtime_session.dart';

final class DefaultAssistantRepository implements AssistantRepository {
  final AssistantRealtimeSession _realtimeSession;

  /// Created once so every getter call does not build another stream pipeline.
  final Stream<AssistantEvent> _events;

  DefaultAssistantRepository({
    required AssistantRealtimeSession realtimeSession,
    AssistantEventModelMapper eventMapper = const AssistantEventModelMapper(),
  }) : _realtimeSession = realtimeSession,
       _events = realtimeSession.events
           .map<AssistantEvent?>(eventMapper.mapOrNull)
           .where((event) => event != null)
           .cast<AssistantEvent>();
  @override
  Stream<AssistantEvent> get events => _events;

  @override
  bool get isReady => _realtimeSession.isReady;

  @override
  Stream<bool> get readinessChanges => _realtimeSession.readinessChanges;

  @override
  void connect() {
    _realtimeSession.connect();
  }

  @override
  Future<void> disconnect() {
    return _realtimeSession.disconnect();
  }

  @override
  Future<void> dispose() {
    return _realtimeSession.dispose();
  }

  @override
  Future<void> sendRequest(AssistantRequest request) {
    final model = TravelRequestEventModel(
      clientMessageId: request.clientMessageId,
      conversationId: request.conversationId,
      tripId: request.tripId,
      message: request.message,
      locale: request.locale,
      sentAt: request.createdAt,
    );
    return _realtimeSession.sendTravelRequest(model);
  }
}
