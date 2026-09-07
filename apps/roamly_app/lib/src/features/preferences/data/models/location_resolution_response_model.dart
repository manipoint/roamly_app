import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/canonical_location.dart';
import 'canonical_location_model.dart';

/// Validated transport response returned by canonical location resolution.
final class LocationResolutionResponseModel {
  LocationResolutionResponseModel._({
    required this.query,
    required List<CanonicalLocation> options,
  }) : options = List<CanonicalLocation>.unmodifiable(options);

  final String query;
  final List<CanonicalLocation> options;

  factory LocationResolutionResponseModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final query = reader.string(
      'query',
      trim: true,
      minLength: 2,
      maxLength: 120,
    );

    final options = reader.list<CanonicalLocation>(
      'options',
      maxLength: 5,
      parseItem: _parseLocation,
    );

    return LocationResolutionResponseModel._(query: query, options: options);
  }

  static CanonicalLocation _parseLocation(Object? value) {
    final reader = JsonReader(<String, Object?>{'location': value});

    return CanonicalLocationModel.fromJson(
      reader.object('location'),
    ).toDomain();
  }
}
