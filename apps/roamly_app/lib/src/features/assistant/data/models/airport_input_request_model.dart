import 'package:roamly_app/src/features/assistant/data/models/airport_option_model.dart';
import 'package:roamly_networking/roamly_networking.dart';

enum AirportInputField { originAirport, destinationAirport }

enum AirportInputStatus { selectionRequired, notFound }

final class AirportInputRequestModel {
  const AirportInputRequestModel._({
    required this.field,
    required this.query,
    required this.status,
    required this.question,
    required this.options,
  });

  final AirportInputField field;
  final String query;
  final AirportInputStatus status;
  final String question;
  final List<AirportOptionModel> options;

  factory AirportInputRequestModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final rawField = reader.string('field', trim: true, minLength: 1);
    final field = switch (rawField) {
      'origin_airport' => AirportInputField.originAirport,
      'destination_airport' => AirportInputField.destinationAirport,
      _ => throw const FormatException('Invalid airport input field.'),
    };
    final query = reader.string(
      'query',
      trim: true,
      minLength: 2,
      maxLength: 120,
    );
    final rawStatus = reader.string('status', trim: true, minLength: 1);
    final status = switch (rawStatus) {
      'selection_required' => AirportInputStatus.selectionRequired,
      'not_found' => AirportInputStatus.notFound,
      _ => throw const FormatException('Invalid airport input status.'),
    };
    final question = reader.string(
      'question',
      trim: true,
      minLength: 1,
      maxLength: 300,
    );
    final options = reader.objectList<AirportOptionModel>(
      'options',
      minLength: 0,
      maxLength: 5,
      parseItem: AirportOptionModel.fromJson,
    );
    switch (status) {
      case AirportInputStatus.selectionRequired:
        if (options.length < 2) {
          throw const FormatException(
            'Airport selection requires at least two options.',
          );
        }

      case AirportInputStatus.notFound:
        if (options.isNotEmpty) {
          throw const FormatException(
            'Airport not-found request cannot contain options.',
          );
        }
    }
    return AirportInputRequestModel._(
      field: field,
      query: query,
      status: status,
      question: question,
      options: options,
    );
  }
}
