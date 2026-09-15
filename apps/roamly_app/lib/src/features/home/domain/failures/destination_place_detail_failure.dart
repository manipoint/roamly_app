import 'package:roamly_core/roamly_core.dart';

enum DestinationPlaceDetailFailureKind {
  invalidDestinationSlug,
  invalidPlaceSlug,
  notFound,
  invalidResponse,
}

final class DestinationPlaceDetailFailure extends AppFailure {
  const DestinationPlaceDetailFailure.invalidDestinationSlug()
    : kind = DestinationPlaceDetailFailureKind.invalidDestinationSlug,
      super(
        code: 'destination_place_invalid_destination_slug',
        isRetryable: false,
      );

  const DestinationPlaceDetailFailure.invalidPlaceSlug()
    : kind = DestinationPlaceDetailFailureKind.invalidPlaceSlug,
      super(code: 'destination_place_invalid_place_slug', isRetryable: false);

  const DestinationPlaceDetailFailure.notFound()
    : kind = DestinationPlaceDetailFailureKind.notFound,
      super(code: 'destination_place_not_found', isRetryable: false);

  const DestinationPlaceDetailFailure.invalidResponse()
    : kind = DestinationPlaceDetailFailureKind.invalidResponse,
      super(code: 'destination_place_invalid_response', isRetryable: false);

  final DestinationPlaceDetailFailureKind kind;
}
