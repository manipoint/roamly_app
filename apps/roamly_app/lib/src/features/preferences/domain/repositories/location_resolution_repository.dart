import 'package:roamly_core/roamly_core.dart';

import '../entities/canonical_location.dart';
import '../policies/location_resolution_policy.dart';

/// Resolves user-entered place text into provider-qualified locations.
abstract interface class LocationResolutionRepository {
  Future<Result<List<CanonicalLocation>>> resolve({
    required String query,
    int limit = LocationResolutionPolicy.maximumResultLimit,
  });
}
