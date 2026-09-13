import 'package:roamly_core/roamly_core.dart';

enum DestinationDetailFailureKind { invalidSlug, notFound, invalidResponse }

final class DestinationDetailFailure extends AppFailure {
  const DestinationDetailFailure.invalidSlug()
    : kind = DestinationDetailFailureKind.invalidSlug,
      super(code: 'destination_detail_invalid_slug', isRetryable: false);

  const DestinationDetailFailure.notFound()
    : kind = DestinationDetailFailureKind.notFound,
      super(code: 'destination_detail_not_found', isRetryable: false);

  const DestinationDetailFailure.invalidResponse()
    : kind = DestinationDetailFailureKind.invalidResponse,
      super(code: 'destination_detail_invalid_response', isRetryable: false);

  final DestinationDetailFailureKind kind;
}
