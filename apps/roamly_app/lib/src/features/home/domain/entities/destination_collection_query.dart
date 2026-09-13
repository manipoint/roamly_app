import '../../../preferences/domain/entities/preference_types.dart';

/// Collections supported by the destination catalogue.
enum DestinationCollectionType { popular, suggested, featured }

/// Identifies a collection independently of its pagination cursor.
final class DestinationCollectionQuery {
  const DestinationCollectionQuery.popular()
    : collection = DestinationCollectionType.popular,
      scope = null;

  const DestinationCollectionQuery.featured()
    : collection = DestinationCollectionType.featured,
      scope = null;

  /// Null scope lets the backend use the user's saved preference.
  const DestinationCollectionQuery.suggested({this.scope})
    : collection = DestinationCollectionType.suggested;

  final DestinationCollectionType collection;
  final RecommendationScope? scope;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DestinationCollectionQuery &&
            collection == other.collection &&
            scope == other.scope;
  }

  @override
  int get hashCode => Object.hash(collection, scope);
}
