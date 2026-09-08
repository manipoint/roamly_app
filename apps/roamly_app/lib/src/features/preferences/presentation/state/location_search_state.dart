import 'package:roamly_core/roamly_core.dart';

import '../../domain/entities/canonical_location.dart';

enum LocationSearchStatus { idle, loading, success, empty, failure }

final class LocationSearchState {
  final String query;
  final LocationSearchStatus status;
  final List<CanonicalLocation> options;
  final AppFailure? failure;

  const LocationSearchState._({
    required this.query,
    required this.status,
    required this.options,
    required this.failure,
  });

  const LocationSearchState.idle({this.query = ''})
    : status = LocationSearchStatus.idle,
      options = const <CanonicalLocation>[],
      failure = null;

  const LocationSearchState.loading({required this.query})
    : status = LocationSearchStatus.loading,
      options = const <CanonicalLocation>[],
      failure = null;

  LocationSearchState.success({
    required String query,
    required Iterable<CanonicalLocation> options,
  }) : this._(
         query: query,
         status: LocationSearchStatus.success,
         options: List<CanonicalLocation>.unmodifiable(options),
         failure: null,
       );
  const LocationSearchState.empty({required this.query})
    : status = LocationSearchStatus.empty,
      options = const <CanonicalLocation>[],
      failure = null;

  const LocationSearchState.failure({
    required this.query,
    required AppFailure failure,
  }) : status = LocationSearchStatus.failure,
       options = const <CanonicalLocation>[],
       failure = failure;

  bool get isLoading => status == LocationSearchStatus.loading;
}
