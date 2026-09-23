enum AssistantClarificationType { airportSelection }

enum AssistantAirportInputField { originAirport, destinationAirport }

enum AssistantAirportInputStatus { selectionRequired, notFound }

enum AssistantAirportLocationType { airport, city }

final class AssistantAirportOption {
  const AssistantAirportOption({
    required this.providerLocationId,
    required this.iataCode,
    required this.locationType,
    required this.name,
    required this.cityName,
    required this.countryName,
    required this.countryCode,
  });

  final String providerLocationId;
  final String iataCode;
  final AssistantAirportLocationType locationType;
  final String name;
  final String? cityName;
  final String? countryName;
  final String countryCode;
}

final class AssistantAirportInputRequest {
  const AssistantAirportInputRequest({
    required this.field,
    required this.query,
    required this.status,
    required this.question,
    required this.options,
  });

  final AssistantAirportInputField field;
  final String query;
  final AssistantAirportInputStatus status;
  final String question;
  final List<AssistantAirportOption> options;
}

final class AssistantClarification {
  const AssistantClarification({required this.type, required this.requests});

  final AssistantClarificationType type;
  final List<AssistantAirportInputRequest> requests;
}
