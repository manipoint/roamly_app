import '../../domain/entities/destination_collection.dart';

/// Maps Home discovery enums to the backend wire contract.
abstract final class HomeDiscoveryEnumMapper {
  static DiscoveryCollectionKind collectionKindFromJson(Object? value) {
    return switch (value) {
      'featured' => DiscoveryCollectionKind.featured,
      'trending' => DiscoveryCollectionKind.trending,
      _ => throw const FormatException('Invalid discovery collection kind.'),
    };
  }
}
