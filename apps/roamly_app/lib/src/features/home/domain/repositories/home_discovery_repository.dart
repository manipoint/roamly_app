import 'package:roamly_core/roamly_core.dart';

import '../entities/destination_collection_query.dart';
import '../entities/destination_detail.dart';
import '../entities/destination_page.dart';
import '../entities/home_discovery.dart';

/// Supplies low-cost Home discovery content for the authenticated user.
abstract interface class HomeDiscoveryRepository {
  /// Returns server-ranked Home sections.
  ///
  /// Implementations must preserve server ordering and must not perform
  /// additional LLM, MCP, or provider requests.
  Future<Result<HomeDiscovery>> getHome({required int limit});
   /// Omit cursor for the first page.
  /// Forward nextCursor unchanged while retaining the same query.
  Future<Result<DestinationPage>> getDestinations({
    required DestinationCollectionQuery query,
    int limit = 20,
    String? cursor,
  });
  /// Returns complete destination editorial content using its stable slug.
  Future<Result<DestinationDetail>> getDestinationDetail({
    required String slug,
  });
}
