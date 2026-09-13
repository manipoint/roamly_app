import 'package:roamly_networking/roamly_networking.dart';

import '../../domain/entities/destination.dart';
import '../../domain/entities/destination_page.dart';
import 'destination_model.dart';

/// Parses a cursor-paginated destination collection response.
final class DestinationPageModel {
  const DestinationPageModel._(this._page);

  final DestinationPage _page;

  factory DestinationPageModel.fromJson(Map<String, Object?> json) {
    final reader = JsonReader(json);

    final items = reader.list<Destination>(
      'items',
      maxLength: 50,
      parseItem: (value) => DestinationModel.fromValue(value).toDomain(),
    );

    final ids = <String>{};
    for (final destination in items) {
      if (!ids.add(destination.id)) {
        throw const FormatException('Duplicate destination ID within a page.');
      }
    }

    final nextCursor = reader.nullable(
      'next_cursor',
      () => reader.string('next_cursor', minLength: 1, maxLength: 512),
    );

    return DestinationPageModel._(
      DestinationPage(items: items, nextCursor: nextCursor),
    );
  }

  DestinationPage toDomain() => _page;
}
