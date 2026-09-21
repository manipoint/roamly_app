import 'dart:async';

import 'package:roamly_app/src/features/assistant/data/models/travel_request_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/sources/assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message_delivery_state.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:roamly_logging/roamly_logging.dart';

import '../../domain/policies/assistant_policy.dart';

/// Serializes and applies all local assistant history mutations.
///
/// Keeping request preparation and incoming-event persistence on the same queue
/// prevents races between an outgoing request and its realtime response.
final class AssistantLocalSyncCoordinator {
  AssistantLocalSyncCoordinator({
    required AssistantLocalDataSource localDataSource,
    required RoamlyLogger logger,
  }) : _localDataSource = localDataSource,
       _logger = logger.child('assistant_local_sync');

  final AssistantLocalDataSource _localDataSource;
  final RoamlyLogger _logger;

  Future<void> _operationTail = Future<void>.value();

  Future<TravelRequestEventModel?> prepareRequest(
    AssistantRequest request, {
    bool requirePendingRecord = false,
  }) {
    return _synchronize(
      () =>
          _prepareRequest(request, requirePendingRecord: requirePendingRecord),
    );
  }

  Future<void> persistEvent(AssistantEvent event) {
    return _synchronize(() => _persistEvent(event));
  }

  Future<List<AssistantRequest>> getPendingRequests({
    int limit = AssistantPolicy.pendingReplayBatchSize,
    DateTime? afterCreatedAt,
    String? afterClientMessageId,
  }) {
    return _synchronize(
      () => _localDataSource.getPendingRequests(
        limit: limit,
        afterCreatedAt: afterCreatedAt,
        afterClientMessageId: afterClientMessageId,
      ),
    );
  }

  Future<void> clear() {
    return _synchronize(_localDataSource.clear);
  }

  Future<void> deleteConversation({required String localId}) {
    return _synchronize(
      () => _localDataSource.deleteConversation(localId: localId),
    );
  }

  Future<List<AssistantMessage>> getMessagesBefore({
    required String conversationLocalId,
    required String beforeId,
    required DateTime beforeCreatedAt,
    required int limit,
  }) {
    return _localDataSource.getMessagesBefore(
      conversationLocalId: conversationLocalId,
      beforeId: beforeId,
      beforeCreatedAt: beforeCreatedAt,
      limit: limit,
    );
  }

  Stream<List<AssistantConversation>> watchConversations({required int limit}) {
    return _localDataSource.watchConversations(limit: limit);
  }

  Stream<List<AssistantMessage>> watchMessages({
    required String conversationLocalId,
    required int limit,
  }) {
    return _localDataSource.watchMessages(
      conversationLocalId: conversationLocalId,
      limit: limit,
    );
  }

  Future<void> drain() => _operationTail;

  Future<T> _synchronize<T>(Future<T> Function() operation) async {
    final previous = _operationTail;
    final release = Completer<void>();
    _operationTail = release.future;

    try {
      await previous;
      return await operation();
    } finally {
      release.complete();
    }
  }

  Future<TravelRequestEventModel?> _prepareRequest(
    AssistantRequest request, {
    required bool requirePendingRecord,
  }) async {
    AssistantRequest? pendingRequest;
    if (requirePendingRecord) {
      pendingRequest = await _localDataSource.getPendingRequest(
        clientMessageId: request.clientMessageId,
      );
      if (pendingRequest == null) {
        return null;
      }
      if (!pendingRequest.hasSameIdempotencyPayloadAs(request)) {
        throw StateError(
          'The persisted pending request does not match the replay request.',
        );
      }
    }

    final existingConversation = await _localDataSource.getConversation(
      localId: request.conversationLocalId,
    );
    final conversation = _resolveConversation(
      request: request,
      existing: existingConversation,
    );
    final existingMessage = await _localDataSource
        .getUserMessageByClientMessageId(
          clientMessageId: request.clientMessageId,
        );

    if (existingMessage == null) {
      final pendingMessage = AssistantMessage(
        id: request.clientMessageId,
        conversationLocalId: request.conversationLocalId,
        clientMessageId: request.clientMessageId,
        author: AssistantMessageAuthor.user,
        content: request.message,
        deliveryState: AssistantMessageDeliveryState.pending,
        createdAt: request.createdAt,
        updatedAt: request.createdAt,
      );
      await _localDataSource.cachePendingRequest(
        conversation: conversation,
        message: pendingMessage,
        request: request,
      );
    } else {
      _validateExistingMessage(message: existingMessage, request: request);
      switch (existingMessage.deliveryState) {
        case AssistantMessageDeliveryState.pending:
          pendingRequest ??= await _localDataSource.getPendingRequest(
            clientMessageId: request.clientMessageId,
          );
          if (pendingRequest != null &&
              !pendingRequest.hasSameIdempotencyPayloadAs(request)) {
            throw StateError(
              'The client message ID is already used by another request.',
            );
          }
          await _localDataSource.cachePendingRequest(
            conversation: conversation,
            message: existingMessage,
            request: request,
          );
          break;
        case AssistantMessageDeliveryState.sent:
        case AssistantMessageDeliveryState.processing:
          if (!requirePendingRecord) {
            return null;
          }
          break;
        case AssistantMessageDeliveryState.completed:
          await _localDataSource.deletePendingRequest(
            clientMessageId: request.clientMessageId,
          );
          return null;
        case AssistantMessageDeliveryState.failed:
          await _localDataSource.deletePendingRequest(
            clientMessageId: request.clientMessageId,
          );
          throw StateError(
            'A failed assistant request requires a new client message ID.',
          );
      }
    }

    return TravelRequestEventModel(
      clientMessageId: request.clientMessageId,
      conversationId: conversation.remoteId,
      tripId: request.tripId,
      message: request.message,
      locale: request.locale,
      sentAt: request.createdAt,
    );
  }

  static AssistantConversation _resolveConversation({
    required AssistantRequest request,
    required AssistantConversation? existing,
  }) {
    if (existing == null) {
      return AssistantConversation(
        createdAt: request.createdAt,
        localId: request.conversationLocalId,
        remoteId: request.conversationId,
        updatedAt: request.createdAt,
      );
    }
    return _mergeConversationRemoteId(
      conversation: existing,
      remoteConversationId: request.conversationId,
      occurredAt: request.createdAt,
    );
  }

  static AssistantConversation _mergeConversationRemoteId({
    required AssistantConversation conversation,
    required String? remoteConversationId,
    required DateTime occurredAt,
  }) {
    final existingRemoteId = conversation.remoteId;
    if (existingRemoteId != null &&
        remoteConversationId != null &&
        existingRemoteId != remoteConversationId) {
      throw StateError(
        'The local conversation is linked to a different remote conversation.',
      );
    }
    final updatedAt = occurredAt.isAfter(conversation.updatedAt)
        ? occurredAt
        : conversation.updatedAt;
    return AssistantConversation(
      localId: conversation.localId,
      remoteId: existingRemoteId ?? remoteConversationId,
      title: conversation.title,
      createdAt: conversation.createdAt,
      updatedAt: updatedAt,
    );
  }

  static void _validateExistingMessage({
    required AssistantMessage message,
    required AssistantRequest request,
  }) {
    final matchesRequest =
        message.author == AssistantMessageAuthor.user &&
        message.conversationLocalId == request.conversationLocalId &&
        message.clientMessageId == request.clientMessageId &&
        message.content == request.message &&
        message.createdAt.millisecondsSinceEpoch ==
            request.createdAt.millisecondsSinceEpoch;
    if (!matchesRequest) {
      throw StateError(
        'The client message ID is already used by another request.',
      );
    }
  }

  Future<void> _persistEvent(AssistantEvent event) async {
    final userMessage = await _localDataSource.getUserMessageByClientMessageId(
      clientMessageId: event.clientMessageId,
    );
    if (userMessage == null) return;

    if (event is AssistantResponseCompleted) {
      final conversation = await _getEventConversation(
        event: event,
        userMessage: userMessage,
      );
      if (conversation == null) return;

      await _persistCompletedResponse(
        conversation: conversation,
        userMessage: userMessage,
        event: event,
      );
      await _localDataSource.deletePendingRequest(
        clientMessageId: event.clientMessageId,
      );
      return;
    }

    final transition = _stateTransitionOf(event);
    final conversation = transition.remoteConversationId == null
        ? null
        : await _getEventConversation(event: event, userMessage: userMessage);
    if (transition.remoteConversationId != null && conversation == null) {
      return;
    }

    await _persistStateTransition(
      conversation: conversation,
      message: userMessage,
      remoteConversationId: transition.remoteConversationId,
      deliveryState: transition.deliveryState,
      occurredAt: event.occurredAt,
    );
    if (transition.removesPendingRequest) {
      await _localDataSource.deletePendingRequest(
        clientMessageId: event.clientMessageId,
      );
    }
  }

  static ({
    AssistantMessageDeliveryState deliveryState,
    String? remoteConversationId,
    bool removesPendingRequest,
  })
  _stateTransitionOf(AssistantEvent event) {
    return switch (event) {
      AssistantRequestRejected() => (
        deliveryState: AssistantMessageDeliveryState.failed,
        remoteConversationId: null,
        removesPendingRequest: true,
      ),
      AssistantRequestAccepted(:final conversationId) => (
        deliveryState: AssistantMessageDeliveryState.sent,
        remoteConversationId: conversationId,
        removesPendingRequest: false,
      ),
      AssistantResponseProcessing(:final conversationId) => (
        deliveryState: AssistantMessageDeliveryState.processing,
        remoteConversationId: conversationId,
        removesPendingRequest: false,
      ),
      AssistantResponseFailed(:final conversationId) => (
        deliveryState: AssistantMessageDeliveryState.failed,
        remoteConversationId: conversationId,
        removesPendingRequest: true,
      ),
      AssistantResponseCompleted() => throw StateError(
        'Completed responses require specialized persistence.',
      ),
    };
  }

  Future<AssistantConversation?> _getEventConversation({
    required AssistantEvent event,
    required AssistantMessage userMessage,
  }) async {
    final conversation = await _localDataSource.getConversation(
      localId: userMessage.conversationLocalId,
    );
    if (conversation == null) {
      _logger.warning(
        'Skipped an assistant event because its conversation is missing.',
        fields: {'eventType': event.runtimeType.toString()},
      );
    }
    return conversation;
  }

  Future<void> _persistStateTransition({
    required AssistantConversation? conversation,
    required AssistantMessage message,
    required String? remoteConversationId,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime occurredAt,
  }) async {
    if (!_shouldApplyState(deliveryState: deliveryState, message: message)) {
      return;
    }
    final updatedAt = occurredAt.isAfter(message.updatedAt)
        ? occurredAt
        : message.updatedAt;
    if (remoteConversationId == null) {
      await _localDataSource.updateMessageDeliveryState(
        messageId: message.id,
        deliveryState: deliveryState,
        updatedAt: updatedAt,
      );
      return;
    }

    if (conversation == null) {
      throw StateError(
        'A remote state transition requires a local conversation.',
      );
    }

    final updatedConversation = _mergeConversationRemoteId(
      conversation: conversation,
      remoteConversationId: remoteConversationId,
      occurredAt: updatedAt,
    );
    final updatedMessage = _copyUserMessage(
      message: message,
      deliveryState: deliveryState,
      updatedAt: updatedAt,
    );
    await _localDataSource.upsertConversationWithMessages(
      conversation: updatedConversation,
      messages: [updatedMessage],
    );
  }

  static bool _shouldApplyState({
    required AssistantMessage message,
    required AssistantMessageDeliveryState deliveryState,
  }) {
    final currentState = message.deliveryState;
    if (currentState == deliveryState) return false;
    if (currentState == AssistantMessageDeliveryState.completed ||
        currentState == AssistantMessageDeliveryState.failed) {
      return false;
    }

    return _stateRank(deliveryState) >= _stateRank(currentState);
  }

  static int _stateRank(AssistantMessageDeliveryState deliveryState) {
    return switch (deliveryState) {
      AssistantMessageDeliveryState.pending => 0,
      AssistantMessageDeliveryState.sent => 1,
      AssistantMessageDeliveryState.processing => 2,
      AssistantMessageDeliveryState.completed => 3,
      AssistantMessageDeliveryState.failed => 3,
    };
  }

  static AssistantMessage _copyUserMessage({
    required AssistantMessage message,
    required AssistantMessageDeliveryState deliveryState,
    required DateTime updatedAt,
  }) {
    return AssistantMessage(
      id: message.id,
      clientMessageId: message.clientMessageId,
      conversationLocalId: message.conversationLocalId,
      author: AssistantMessageAuthor.user,
      content: message.content,
      deliveryState: deliveryState,
      createdAt: message.createdAt,
      updatedAt: updatedAt,
    );
  }

  Future<void> _persistCompletedResponse({
    required AssistantConversation conversation,
    required AssistantMessage userMessage,
    required AssistantResponseCompleted event,
  }) async {
    if (!_shouldApplyState(
      message: userMessage,
      deliveryState: AssistantMessageDeliveryState.completed,
    )) {
      return;
    }
    final responseTimestamp = _resolveResponseTimestamp(
      userMessage: userMessage,
      occurredAt: event.occurredAt,
    );
    final updatedConversation = _mergeConversationRemoteId(
      conversation: conversation,
      remoteConversationId: event.conversationId,
      occurredAt: responseTimestamp,
    );
    final completedUserMessage = _copyUserMessage(
      message: userMessage,
      deliveryState: AssistantMessageDeliveryState.completed,
      updatedAt: responseTimestamp,
    );
    final assistantMessage = AssistantMessage(
      id: event.assistantMessageId,
      conversationLocalId: userMessage.conversationLocalId,
      clientMessageId: event.clientMessageId,
      assistantMessageId: event.assistantMessageId,
      itineraryId: event.itineraryId,
      author: AssistantMessageAuthor.assistant,
      content: event.content,
      deliveryState: AssistantMessageDeliveryState.completed,
      createdAt: responseTimestamp,
      updatedAt: responseTimestamp,
    );
    await _localDataSource.upsertConversationWithMessages(
      conversation: updatedConversation,
      messages: [completedUserMessage, assistantMessage],
    );
  }

  static DateTime _resolveResponseTimestamp({
    required AssistantMessage userMessage,
    required DateTime occurredAt,
  }) {
    final minimumResponseTime = userMessage.createdAt.add(
      const Duration(milliseconds: 1),
    );

    DateTime resolved = occurredAt.isAfter(minimumResponseTime)
        ? occurredAt
        : minimumResponseTime;

    if (userMessage.updatedAt.isAfter(resolved)) {
      resolved = userMessage.updatedAt;
    }

    return resolved;
  }
}
