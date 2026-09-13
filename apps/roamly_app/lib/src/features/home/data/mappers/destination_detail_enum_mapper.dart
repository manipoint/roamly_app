import '../../domain/entities/destination_detail.dart';

abstract final class DestinationDetailEnumMapper {
  static DestinationType destinationTypeFromJson(String value) {
    return switch (value) {
      'city' => DestinationType.city,
      'region' => DestinationType.region,
      'island' => DestinationType.island,
      'country' => DestinationType.country,
      _ => throw const FormatException('Invalid destination type.'),
    };
  }
}
