import 'package:roamly_core/roamly_core.dart';

import '../entities/destination_collection_query.dart';
import '../entities/destination_page.dart';

/// Supplies backend-ranked, paginated destination collections.
abstract interface class DestinationCatalogueRepository {
  /// Returns one page while preserving server ordering.
  ///
  /// Omit cursor for the first page. For subsequent pages, pass the
  /// returned nextCursor unchanged and retain the same query.
  ///
  /// Implementations validate limit (1–50) before network work and
  /// expose invalid-cursor failures separately so callers can restart.
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  });
}
