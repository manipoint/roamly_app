import 'package:roamly_core/roamly_core.dart';

enum DestinationCatalogueFailureKind {
  invalidLimit,
  invalidCursor,
  invalidResponse,
}

final class DestinationCatalogueFailure extends AppFailure {
  const DestinationCatalogueFailure.invalidLimit()
    : kind = DestinationCatalogueFailureKind.invalidLimit,
      super(code: 'destination_catalogue_invalid_limit', isRetryable: false);

  /// The caller must restart pagination without the old cursor.
  const DestinationCatalogueFailure.invalidCursor()
    : kind = DestinationCatalogueFailureKind.invalidCursor,
      super(code: 'destination_catalogue_invalid_cursor', isRetryable: false);

  const DestinationCatalogueFailure.invalidResponse()
    : kind = DestinationCatalogueFailureKind.invalidResponse,
      super(code: 'destination_catalogue_invalid_response', isRetryable: false);

  final DestinationCatalogueFailureKind kind;
}
