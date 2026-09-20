import 'package:roamly_app/src/features/assistant/data/mappers/assistant_event_model_mapper.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';

import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';

import '../../domain/repositories/assistant_repository.dart';
import '../models/travel_request_event_model.dart';
import '../services/assistant_realtime_session.dart';
import '../sources/assistant_local_data_source.dart';

final class DefaultAssistantRepository implements AssistantRepository {
  final AssistantRealtimeSession _realtimeSession;
  final AssistantLocalDataSource _localDataSource;

  /// Created once so every getter call does not build another stream pipeline.
  final Stream<AssistantEvent> _events;

  DefaultAssistantRepository({
    required AssistantRealtimeSession realtimeSession,
    required AssistantLocalDataSource localDataSource,
    AssistantEventModelMapper eventMapper = const AssistantEventModelMapper(),
  }) : _realtimeSession = realtimeSession,
       _localDataSource = localDataSource,
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

  @override
  Future<void> clearLocalHistory() {
    return _localDataSource.clear();
  }

  @override
  Future<void> deleteConversation({required String localId}) {
    return _localDataSource.deleteConversation(localId: localId);
  }

  @override
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required String beforeId,
    required DateTime beforeCreatedAt,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    return _localDataSource.getMessagesBefore(
      conversationLocalId: conversationLocalId,
      beforeId: beforeId,
      beforeCreatedAt: beforeCreatedAt,
      limit: limit,
    );
  }

  @override
  Stream<List<AssistantConversation>> watchConversations({
    int limit = AssistantPolicy.defaultConversationsLimit,
  }) {
    return _localDataSource.watchConversations(limit: limit);
  }

  @override
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    return _localDataSource.watchMessages(
      conversationLocalId: conversationLocalId,
      limit: limit,
    );
  }
}
