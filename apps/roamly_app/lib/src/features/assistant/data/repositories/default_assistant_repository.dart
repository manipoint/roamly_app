import 'dart:async';

import 'package:roamly_core/roamly_core.dart';
import 'package:roamly_app/src/features/assistant/data/mappers/assistant_event_model_mapper.dart';
import 'package:roamly_app/src/features/assistant/data/services/assistant_local_sync_coordinator.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_logging/roamly_logging.dart';
import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/repositories/assistant_repository.dart';
import '../services/assistant_realtime_session.dart';
import '../sources/assistant_local_data_source.dart';
import '../sources/assistant_remote_data_source.dart';

final class DefaultAssistantRepository implements AssistantRepository {
  DefaultAssistantRepository({
    required AssistantRealtimeSession realtimeSession,
    required AssistantLocalDataSource localDataSource,
    required AssistantRemoteDataSource remoteDataSource,
    required ApiRequestExecutor requestExecutor,
    required RoamlyLogger logger,
    Timer Function(Duration, void Function()) recoveryTimerFactory = Timer.new,
    AssistantEventModelMapper eventMapper = const AssistantEventModelMapper(),
  }) : _recoveryTimerFactory = recoveryTimerFactory,
       _realtimeSession = realtimeSession,
       _remoteDataSource = remoteDataSource,
       _requestExecutor = requestExecutor,
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
  final AssistantRemoteDataSource _remoteDataSource;
  final ApiRequestExecutor _requestExecutor;
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
  bool _replayRequested = false;
  final Timer Function(Duration, void Function()) _recoveryTimerFactory;
  final Set<String> _recoveringIds = {};
  Timer? _recoveryTimer;
  Duration _recoveryDelay = AssistantPolicy.initialRecoveryDelay;
  bool _recoveryPaused = false;

  void _stopRecovery() {
    _recoveryTimer?.cancel();
    _recoveryTimer = null;
  }

  void _finishRecovery(String clientMessageId) {
    _recoveringIds.remove(clientMessageId);
    if (_recoveringIds.isEmpty) {
      _stopRecovery();
      _recoveryDelay = AssistantPolicy.initialRecoveryDelay;
    }
  }

  void _scheduleRecovery() {
    if (_disposed ||
        _recoveryPaused ||
        !_realtimeSession.isReady ||
        _recoveringIds.isEmpty ||
        _recoveryTimer != null ||
        _replayFuture != null) {
      return;
    }
    _recoveryTimer = _recoveryTimerFactory(_recoveryDelay, () {
      _recoveryTimer = null;
      final doubled = _recoveryDelay * 2;
      _recoveryDelay = doubled > AssistantPolicy.maximumRecoveryDelay
          ? AssistantPolicy.maximumRecoveryDelay
          : doubled;
      _schedulePendingReplay();
    });
  }

  @override
  Stream<AssistantEvent> get events => _events;

  @override
  bool get isReady => _realtimeSession.isReady;

  @override
  Stream<bool> get readinessChanges => _realtimeSession.readinessChanges;

  @override
  void connect() {
    _ensureActive();
    _recoveryPaused = false;
    _realtimeSession.connect();
  }

  @override
  Future<void> disconnect() {
    if (_disposed) return Future<void>.value();

    _recoveryPaused = true;
    _stopRecovery();
    return _realtimeSession.disconnect();
  }

  @override
  Future<void> dispose() {
    final disposing = _disposeFuture;
    if (disposing != null) return disposing;

    _disposed = true;
    _stopRecovery();
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

          if (model == null) {
            _finishRecovery(request.clientMessageId);
            completer.complete();
            return;
          }
          if (_disposed || _recoveryPaused || !_realtimeSession.isReady) {
            completer.complete();
            return;
          }
          _recoveringIds.add(request.clientMessageId);
          try {
            await _realtimeSession.sendTravelRequest(model);
          } catch (error, stackTrace) {
            if (error is WebSocketFailure &&
                error.kind == WebSocketFailureKind.messageTooLarge) {
              await _localSync.failPendingRequest(
                clientMessageId: request.clientMessageId,
              );
            }
            // Only known transient transport failures mean "queued".
            // Session/authentication and unexpected failures must reach callers.
            if (error is! WebSocketFailure || !error.isRetryable) rethrow;
            _logger.warning(
              'Assistant request dispatch failed and remains queued.',
              fields: {'errorType': error.runtimeType.toString()},
              stackTrace: stackTrace,
            );
          }

          completer.complete();
        } catch (error, stackTrace) {
          _finishRecovery(request.clientMessageId);
          completer.completeError(error, stackTrace);
        } finally {
          final currentOperation = _sendOperations[request.clientMessageId];

          if (currentOperation != null &&
              identical(currentOperation.completer, completer)) {
            _sendOperations.remove(request.clientMessageId);
          }
          _scheduleRecovery();
        }
      })(),
    );

    return completer.future;
  }

  @override
  Future<void> clearLocalHistory() async {
    _ensureActive();
    await _localSync.clear();
    _recoveringIds.clear();
    _stopRecovery();
    _recoveryDelay = AssistantPolicy.initialRecoveryDelay;
  }

  @override
  Future<void> deleteConversation({required String localId}) async {
    _ensureActive();
    final conversation = await _localSync.getConversation(localId: localId);
    if (conversation == null) return;

    final remoteId = conversation.remoteId;
    if (remoteId != null) {
      final result = await _requestExecutor.execute<void>(
        () => _remoteDataSource.deleteConversation(conversationId: remoteId),
      );
      if (result case FailureResult<void>(:final failure)) {
        // DELETE is idempotent from the client's perspective: an already
        // absent remote conversation has reached the requested state.
        if (failure is! NetworkFailure || failure.statusCode != 404) {
          throw failure;
        }
      }
    }

    await _localSync.deleteConversation(localId: localId);
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
    _stopRecovery();
    if (isReady) {
      _recoveryDelay = AssistantPolicy.initialRecoveryDelay;
      _schedulePendingReplay();
    }
  }

  void _schedulePendingReplay() {
    if (_disposed || _recoveryPaused || !_realtimeSession.isReady) return;
    _stopRecovery();
    _replayRequested = true;
    if (_replayFuture != null) return;

    _replayRequested = false;
    _replayFuture = _replayPendingRequests().whenComplete(() {
      _replayFuture = null;
      if (!_disposed && _realtimeSession.isReady && _replayRequested) {
        _schedulePendingReplay();
      } else {
        _scheduleRecovery();
      }
    });
    unawaited(_replayFuture);
  }

  Future<void> _replayPendingRequests() async {
    DateTime? cursorCreatedAt;
    String? cursorClientMessageId;
    final seen = <String>{};
    final recoveringAtStart = Set<String>.of(_recoveringIds);

    try {
      while (!_disposed && !_recoveryPaused && _realtimeSession.isReady) {
        final requests = await _localSync.getPendingRequests(
          limit: AssistantPolicy.pendingReplayBatchSize,
          afterCreatedAt: cursorCreatedAt,
          afterClientMessageId: cursorClientMessageId,
        );

        for (final request in requests) {
          seen.add(request.clientMessageId);
          if (_disposed || _recoveryPaused || !_realtimeSession.isReady) {
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

        if (requests.length < AssistantPolicy.pendingReplayBatchSize) {
          for (final id in recoveringAtStart.difference(seen)) {
            _finishRecovery(id);
          }
          return;
        }
        final lastRequest = requests.last;
        cursorCreatedAt = lastRequest.createdAt;
        cursorClientMessageId = lastRequest.clientMessageId;
      }
    } catch (error, stackTrace) {
      _logger.error(
        'Failed to load pending assistant requests.',
        fields: {'errorType': error.runtimeType.toString()},
        stackTrace: stackTrace,
      );
    }
  }

  Future<AssistantEvent> _persistAndForwardEvent(AssistantEvent event) async {
    final failureFields = switch (event) {
      AssistantRequestRejected(:final reason) => <String, Object>{
        'eventType': 'travel.request.rejected',
        'reason': reason.name,
      },
      AssistantResponseFailed(:final reason, :final conversationId) =>
        <String, Object>{
          'eventType': 'travel.response.failed',
          'reason': reason.name,
          'conversationId': conversationId,
        },
      _ => null,
    };
    if (failureFields != null) {
      _logger.warning(
        'Assistant request failed.',
        fields: {...failureFields, 'clientMessageId': event.clientMessageId},
      );
    }
    try {
      await _localSync.persistEvent(event);
      if (event is AssistantResponseWithMessage ||
          event is AssistantResponseFailed ||
          event is AssistantRequestRejected) {
        _finishRecovery(event.clientMessageId);
      }
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
