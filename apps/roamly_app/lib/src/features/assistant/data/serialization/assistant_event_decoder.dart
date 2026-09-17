import 'dart:convert';

import 'package:roamly_networking/roamly_networking.dart';

import '../models/assistant_incoming_event_model.dart';
import '../models/connection_pong_event_model.dart';
import '../models/connection_ready_event_model.dart';
import '../models/travel_request_accepted_event_model.dart';
import '../models/travel_request_rejected_event_model.dart';
import '../models/travel_response_completed_event_model.dart';
import '../models/travel_response_failed_event_model.dart';
import '../models/travel_response_processing_event_model.dart';

final class AssistantEventDecoder {
  const AssistantEventDecoder();

  AssistantIncomingEventModel decode(String text) {
    final Object? value;
    try {
      value = jsonDecode(text);
    } on FormatException {
      throw const FormatException('Invalid Assistant event JSON.');
    }

    final json = JsonReader(<String, Object?>{'event': value}).object('event');
    return decodeJson(json);
  }

  AssistantIncomingEventModel decodeJson(Map<String, Object?> json) {
    final type = JsonReader(json).string('type');
    return switch (type) {
      'connection.ready' => ConnectionReadyEventModel.fromJson(json),
      'connection.pong' => ConnectionPongEventModel.fromJson(json),
      'travel.request.accepted' => TravelRequestAcceptedEventModel.fromJson(
        json,
      ),
      'travel.request.rejected' => TravelRequestRejectedEventModel.fromJson(
        json,
      ),
      'travel.response.processing' =>
        TravelResponseProcessingEventModel.fromJson(json),
      'travel.response.completed' => TravelResponseCompletedEventModel.fromJson(
        json,
      ),
      'travel.response.failed' => TravelResponseFailedEventModel.fromJson(json),
      _ => throw const FormatException('Unsupported Assistant event type.'),
    };
  }
}
