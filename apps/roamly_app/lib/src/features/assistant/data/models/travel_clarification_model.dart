import 'package:roamly_networking/roamly_networking.dart';

import 'airport_input_request_model.dart';

enum TravelClarificationType { airportSelection }

final class TravelClarificationModel {
  const TravelClarificationModel._({
    required this.type,
    required this.requests,
  });

  final TravelClarificationType type;
  final List<AirportInputRequestModel> requests;

  factory TravelClarificationModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final rawType = reader.string('type', trim: true, minLength: 1);

    final type = switch (rawType) {
      'airport_selection' => TravelClarificationType.airportSelection,
      _ => throw const FormatException(
        'Unsupported travel clarification type.',
      ),
    };

    final requests = reader.objectList<AirportInputRequestModel>(
      'requests',
      minLength: 1,
      maxLength: 2,
      parseItem: AirportInputRequestModel.fromJson,
    );

    return TravelClarificationModel._(type: type, requests: requests);
  }
}
