import 'dart:async';

import 'package:roamly_app/src/features/assistant/data/mappers/assistant_event_model_mapper.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_local_sync_coordinator.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_logging/roamly_logging.dart';

import '../../domain/repositories/assistant_repository.dart';
import '../services/assistant_realtime_session.dart';
import '../sources/assistant_local_data_source.dart';

final class DefaultAssistantRepository implements AssistantRepository {
  DefaultAssistantRepository({
    required AssistantRealtimeSession realtimeSession,
    required AssistantLocalDataSource localDataSource,
    required RoamlyLogger logger,
    AssistantEventModelMapper eventMapper = const AssistantEventModelMapper(),
  }) : _realtimeSession = realtimeSession,
       _logger = logger.child('assistant_repository'),
       _localSync = AssistantLocalSyncCoordinator(
         localDataSource: localDataSource,
         logger: logger,
       ) {
    _events = _eventsController.stream;
    _eventSubscription = realtimeSession.events
        .map<AssistantEvent?>(eventMapper.mapOrNull)
        .where((event) => event != null)
        .cast<AssistantEvent>()
        .asyncMap(_persistAndForwardEvent)
        .listen(
          _eventsController.add,
          onError: _forwardRealtimeError,
          onDone: _closeEvents,
        );
    _readinessSubscription = realtimeSession.readinessChanges.listen(
      _handleReadinessChange,
      onError: _logReadinessError,
    );
    if (realtimeSession.isReady) _schedulePendingReplay();
  }

  final AssistantRealtimeSession _realtimeSession;
  final AssistantLocalSyncCoordinator _localSync;
  final RoamlyLogger _logger;
  final StreamController<AssistantEvent> _eventsController =
      StreamController<AssistantEvent>.broadcast();
  final Map<String, ({AssistantRequest request, Completer<void> completer})>
  _sendOperations = {};

  late final Stream<AssistantEvent> _events;
  late final StreamSubscription<AssistantEvent> _eventSubscription;
  late final StreamSubscription<bool> _readinessSubscription;
  Future<void>? _replayFuture;
  Future<void>? _disposeFuture;
  bool _disposed = false;

  @override
  Stream<AssistantEvent> get events => _events;

  @override
  bool get isReady => _realtimeSession.isReady;

  @override
  Stream<bool> get readinessChanges => _realtimeSession.readinessChanges;

  @override
  void connect() {
    _ensureActive();
    _realtimeSession.connect();
  }

  @override
  Future<void> disconnect() {
    _ensureActive();
    return _realtimeSession.disconnect();
  }

  @override
  Future<void> dispose() {
    final disposing = _disposeFuture;
    if (disposing != null) return disposing;

    _disposed = true;
    final future = _dispose();
    _disposeFuture = future;
    return future;
  }

  @override
  Future<void> sendRequest(
    AssistantRequest request, {
    bool requirePendingRecord = false,
  }) {
    _ensureActive();
    final existingOperation = _sendOperations[request.clientMessageId];
    if (existingOperation != null) {
      if (!existingOperation.request.hasSameIdempotencyPayloadAs(request)) {
        return Future<void>.error(
          StateError(
            'The client message ID is already used by an in-flight request.',
          ),
        );
      }
      return existingOperation.completer.future;
    }

    final completer = Completer<void>();
    _sendOperations[request.clientMessageId] = (
      request: request,
      completer: completer,
    );
    unawaited(
      (() async {
        try {
          final model = await _localSync.prepareRequest(
            request,
            requirePendingRecord: requirePendingRecord,
          );

          if (model != null) {
            await _realtimeSession.sendTravelRequest(model);
          }

          completer.complete();
        } catch (error, stackTrace) {
          completer.completeError(error, stackTrace);
        } finally {
          final currentOperation = _sendOperations[request.clientMessageId];

          if (currentOperation != null &&
              identical(currentOperation.completer, completer)) {
            _sendOperations.remove(request.clientMessageId);
          }
        }
      })(),
    );

    return completer.future;
  }

  @override
  Future<void> clearLocalHistory() {
    _ensureActive();
    return _localSync.clear();
  }

  @override
  Future<void> deleteConversation({required String localId}) {
    _ensureActive();
    return _localSync.deleteConversation(localId: localId);
  }

  @override
  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required String beforeId,
    required DateTime beforeCreatedAt,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    _ensureActive();
    return _localSync.getMessagesBefore(
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
    _ensureActive();
    return _localSync.watchConversations(limit: limit);
  }

  @override
  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    int limit = AssistantPolicy.defaultMessagesLimit,
  }) {
    _ensureActive();
    return _localSync.watchMessages(
      conversationLocalId: conversationLocalId,
      limit: limit,
    );
  }

  void _handleReadinessChange(bool isReady) {
    if (isReady) _schedulePendingReplay();
  }

  void _schedulePendingReplay() {
    if (_disposed || _replayFuture != null) return;
    final replay = _replayPendingRequests();
    _replayFuture = replay;
    unawaited(replay);
  }

  Future<void> _replayPendingRequests() async {
    DateTime? cursorCreatedAt;
    String? cursorClientMessageId;

    try {
      while (!_disposed && _realtimeSession.isReady) {
        final requests = await _localSync.getPendingRequests(
          limit: AssistantPolicy.pendingReplayBatchSize,
          afterCreatedAt: cursorCreatedAt,
          afterClientMessageId: cursorClientMessageId,
        );

        if (requests.isEmpty) {
          return;
        }

        for (final request in requests) {
          if (_disposed || !_realtimeSession.isReady) {
            return;
          }

          try {
            await sendRequest(request, requirePendingRecord: true);
          } catch (error, stackTrace) {
            _logger.warning(
              'Failed to replay a pending assistant request.',
              fields: {'errorType': error.runtimeType.toString()},
              stackTrace: stackTrace,
            );

            if (!_realtimeSession.isReady) {
              return;
            }
          }
        }

        final lastRequest = requests.last;
        cursorCreatedAt = lastRequest.createdAt;
        cursorClientMessageId = lastRequest.clientMessageId;

        if (requests.length < AssistantPolicy.pendingReplayBatchSize) {
          return;
        }
      }
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to load pending assistant requests.',
        fields: {'errorType': error.runtimeType.toString()},
        stackTrace: stackTrace,
      );
    } finally {
      _replayFuture = null;
    }
  }

  Future<AssistantEvent> _persistAndForwardEvent(AssistantEvent event) async {
    try {
      await _localSync.persistEvent(event);
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to persist an assistant event.',
        fields: {
          'eventType': event.runtimeType.toString(),
          'errorType': error.runtimeType.toString(),
        },
        stackTrace: stackTrace,
      );
    }
    return event;
  }

  void _forwardRealtimeError(Object error, StackTrace stackTrace) {
    if (!_eventsController.isClosed) {
      _eventsController.addError(error, stackTrace);
    }
  }

  void _logReadinessError(Object error, StackTrace stackTrace) {
    _logger.error(
      'Assistant readiness stream failed.',
      fields: {'errorType': error.runtimeType.toString()},
      stackTrace: stackTrace,
    );
  }

  void _closeEvents() {
    if (!_eventsController.isClosed) unawaited(_eventsController.close());
  }

  void _ensureActive() {
    if (_disposed) throw StateError('AssistantRepository is disposed.');
  }

  Future<void> _dispose() async {
    try {
      await Future.wait<void>([
        _eventSubscription.cancel(),
        _readinessSubscription.cancel(),
      ]);
      await _localSync.drain();
    } finally {
      try {
        await _realtimeSession.dispose();
      } finally {
        _closeEvents();
      }
    }
  }
}
