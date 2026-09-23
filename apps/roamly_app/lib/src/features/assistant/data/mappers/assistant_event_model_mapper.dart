import 'package:roamly_app/src/features/assistant/data/models/assistant_incoming_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_pong_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/connection_ready_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_request_accepted_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_input_required_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_clarification_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_completed_event_model.dart';
import 'package:roamly_app/src/features/assistant/data/models/travel_response_processing_event_model.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_event.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_clarification.dart';

import '../models/airport_input_request_model.dart';
import '../models/airport_option_model.dart';

import '../models/travel_request_rejected_event_model.dart';
import '../models/travel_response_failed_event_model.dart';

final class AssistantEventModelMapper {
  const AssistantEventModelMapper();
  AssistantEvent? mapOrNull(AssistantIncomingEventModel model) {
    return switch (model) {
      ConnectionReadyEventModel() => null,
      ConnectionPongEventModel() => null,

      TravelRequestAcceptedEventModel event => AssistantRequestAccepted(
        occurredAt: event.sentAt,
        clientMessageId: event.clientMessageId,
        conversationId: event.conversationId,
      ),
      TravelRequestRejectedEventModel event => AssistantRequestRejected(
        occurredAt: event.sentAt,
        clientMessageId: event.clientMessageId,
        reason: _mapRejectionReason(event.code),
      ),
      TravelResponseProcessingEventModel event => AssistantResponseProcessing(
        occurredAt: event.sentAt,
        clientMessageId: event.clientMessageId,
        conversationId: event.conversationId,
      ),
      TravelInputRequiredEventModel event => AssistantInputRequired(
        occurredAt: event.sentAt,
        clientMessageId: event.clientMessageId,
        conversationId: event.conversationId,
        assistantMessageId: event.assistantMessageId,
        content: event.content,
        isDuplicate: event.isDuplicate,
        clarification: _mapClarification(event.clarification),
      ),
      TravelResponseCompletedEventModel event => AssistantResponseCompleted(
        occurredAt: event.sentAt,
        clientMessageId: event.clientMessageId,
        conversationId: event.conversationId,
        assistantMessageId: event.assistantMessageId,
        content: event.content,
        isDuplicate: event.isDuplicate,
        itineraryId: event.itineraryId,
      ),
      TravelResponseFailedEventModel event => AssistantResponseFailed(
        occurredAt: event.sentAt,
        clientMessageId: event.clientMessageId,
        conversationId: event.conversationId,
        reason: _mapFailureReason(event.code),
      ),
      _ => throw StateError('Unsupported Assistant event model type.'),
    };
  }

  static AssistantClarification _mapClarification(
    TravelClarificationModel clarification,
  ) {
    return AssistantClarification(
      type: switch (clarification.type) {
        TravelClarificationType.airportSelection =>
          AssistantClarificationType.airportSelection,
      },
      requests: clarification.requests
          .map(_mapAirportRequest)
          .toList(growable: false),
    );
  }

  static AssistantAirportInputRequest _mapAirportRequest(
    AirportInputRequestModel request,
  ) {
    return AssistantAirportInputRequest(
      field: switch (request.field) {
        AirportInputField.originAirport =>
          AssistantAirportInputField.originAirport,
        AirportInputField.destinationAirport =>
          AssistantAirportInputField.destinationAirport,
      },
      query: request.query,
      status: switch (request.status) {
        AirportInputStatus.selectionRequired =>
          AssistantAirportInputStatus.selectionRequired,
        AirportInputStatus.notFound => AssistantAirportInputStatus.notFound,
      },
      question: request.question,
      options: request.options.map(_mapAirportOption).toList(growable: false),
    );
  }

  static AssistantAirportOption _mapAirportOption(AirportOptionModel option) {
    return AssistantAirportOption(
      providerLocationId: option.providerLocationId,
      iataCode: option.iataCode,
      locationType: switch (option.locationType) {
        AirportLocationType.airport => AssistantAirportLocationType.airport,
        AirportLocationType.city => AssistantAirportLocationType.city,
      },
      name: option.name,
      cityName: option.cityName,
      countryName: option.countryName,
      countryCode: option.countryCode,
    );
  }

  static AssistantRequestRejectionReason _mapRejectionReason(
    TravelRequestRejectionCode code,
  ) {
    return switch (code) {
      TravelRequestRejectionCode.clientMessageConflict =>
        AssistantRequestRejectionReason.clientMessageConflict,
      TravelRequestRejectionCode.conversationNotFound =>
        AssistantRequestRejectionReason.conversationNotFound,
      TravelRequestRejectionCode.tripNotFound =>
        AssistantRequestRejectionReason.tripNotFound,
      TravelRequestRejectionCode.unknown =>
        AssistantRequestRejectionReason.unknown,
    };
  }

  static AssistantResponseFailureReason _mapFailureReason(
    TravelResponseFailureCode code,
  ) {
    return switch (code) {
      TravelResponseFailureCode.attemptsExhausted =>
        AssistantResponseFailureReason.attemptsExhausted,
      TravelResponseFailureCode.generationFailed =>
        AssistantResponseFailureReason.generationFailed,
      TravelResponseFailureCode.providerError =>
        AssistantResponseFailureReason.providerError,
      TravelResponseFailureCode.unknown =>
        AssistantResponseFailureReason.unknown,
    };
  }
}
