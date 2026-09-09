import 'package:roamly_core/roamly_core.dart';

import '../entities/home_discovery.dart';

/// Supplies low-cost Home discovery content for the authenticated user.
abstract interface class HomeDiscoveryRepository {
  /// Returns server-ranked Home sections.
  ///
  /// Implementations must preserve server ordering and must not perform
  /// additional LLM, MCP, or provider requests.
  Future<Result<HomeDiscovery>> getHome({required int limit});
}
