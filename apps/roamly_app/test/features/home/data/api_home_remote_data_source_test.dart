import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/home/data/sources/api_home_remote_data_source.dart';
import 'package:roamly_app/src/features/home/domain/policies/home_discovery_policy.dart';
import 'package:roamly_networking/roamly_networking.dart';

Map<String, Object?> _destination() => <String, Object?>{
  'id': '00000000-0000-4000-8000-000000000001',
  'slug': 'lahore-pakistan',
  'name': 'Lahore',
  'country_name': 'Pakistan',
  'country_code': 'PK',
  'summary': 'Historic architecture and food culture.',
  'image_url': 'https://images.example.test/lahore.webp',
  'image_alt': 'Lahore Fort at sunset',
  'latitude': 31.5204,
  'longitude': 74.3587,
  'budget_tier': 'mid_range',
  'styles': <Object?>['culture'],
  'interests': <Object?>['history'],
};

Map<String, Object?> _response() => <String, Object?>{
  'personalization_ready': true,
  'suggested': <Object?>[_destination()],
  'popular': <Object?>[],
  'spotlight': <String, Object?>{'kind': 'featured', 'items': <Object?>[]},
};

Map<String, Object?> _detailResponse() => <String, Object?>{
  'id': '00000000-0000-4000-8000-000000000001',
  'slug': 'bali-indonesia',
  'name': 'Bali',
  'destination_type': 'island',
  'country_name': 'Indonesia',
  'country_code': 'ID',
  'summary': 'A tropical island rich in culture and natural beauty.',
  'full_description':
      'Explore beaches, temples, local traditions, and scenic landscapes.',
  'location': <String, Object?>{
    'latitude': -8.4095,
    'longitude': 115.1889,
    'map_zoom': 9,
  },
  'budget_tier': 'mid_range',
  'styles': <Object?>['beaches'],
  'interests': <Object?>['photography'],
  'gallery': <Object?>[],
  'places': <Object?>[],
  'places_next_cursor': null,
  'has_more_places': false,
};

final class _Client implements ApiClient {
  Object? response = _response();
  Object? error;
  int calls = 0;
  String? path;
  Map<String, Object?>? queryParameters;

  @override
  Future<Object?> get(
    String path, {
    Map<String, Object?>? queryParameters,
    Map<String, Object?>? headers,
  }) async {
    calls++;
    this.path = path;
    this.queryParameters = queryParameters;
    if (error case final value?) {
      throw value;
    }
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Client client;
  late ApiHomeRemoteDataSource source;

  setUp(() {
    client = _Client();
    source = ApiHomeRemoteDataSource(authenticatedClient: client);
  });

  test('sends one bounded authenticated Home request', () async {
    final model = await source.getHome(limit: 4);

    expect(client.calls, 1);
    expect(client.path, 'home');
    expect(client.queryParameters, <String, Object?>{'limit': 4});
    expect(model.toDomain().suggested.single.name, 'Lahore');
  });

  test('accepts both documented limit boundaries', () async {
    await source.getHome(limit: HomeDiscoveryPolicy.minimumSectionLimit);
    await source.getHome(limit: HomeDiscoveryPolicy.maximumSectionLimit);

    expect(client.calls, 2);
  });

  test('rejects invalid limits without network work', () async {
    for (final limit in <int>[0, 7]) {
      await expectLater(
        source.getHome(limit: limit),
        throwsA(isA<RangeError>()),
      );
    }

    expect(client.calls, 0);
  });

  test('rejects malformed response roots', () async {
    for (final response in <Object?>[
      null,
      <Object?>[],
      'invalid',
      <String, Object?>{},
    ]) {
      client.response = response;
      await expectLater(source.getHome(limit: 3), throwsFormatException);
    }

    expect(client.calls, 4);
  });

  test('propagates transport failures without retrying', () async {
    final error = Exception('transport failure');
    client.error = error;

    await expectLater(source.getHome(limit: 3), throwsA(same(error)));
    expect(client.calls, 1);
  });

  group('getDestinationDetail', () {
    test('normalizes the slug used in the request path', () async {
      client.response = _detailResponse();

      final model = await source.getDestinationDetail(
        slug: '  bali-indonesia  ',
      );

      expect(client.calls, 1);
      expect(client.path, 'destinations/bali-indonesia');
      expect(client.queryParameters, isNull);
      expect(model.toDomain().slug, 'bali-indonesia');
    });

    test('rejects invalid slugs before network work', () async {
      for (final slug in ['', '   ', 'Bali Indonesia', '../bali']) {
        await expectLater(
          source.getDestinationDetail(slug: slug),
          throwsA(isA<ArgumentError>()),
        );
      }

      expect(client.calls, 0);
    });

    test('rejects malformed detail response roots', () async {
      for (final response in <Object?>[null, <Object?>[], 'invalid']) {
        client.response = response;
        await expectLater(
          source.getDestinationDetail(slug: 'bali-indonesia'),
          throwsFormatException,
        );
      }

      expect(client.calls, 3);
    });

    test('propagates detail transport failures without retrying', () async {
      final error = Exception('transport failure');
      client.error = error;

      await expectLater(
        source.getDestinationDetail(slug: 'bali-indonesia'),
        throwsA(same(error)),
      );
      expect(client.calls, 1);
    });
  });
}
