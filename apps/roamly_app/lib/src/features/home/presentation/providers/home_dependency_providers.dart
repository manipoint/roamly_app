import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/home/domain/repositories/home_discovery_repository.dart';

final homeDiscoveryRepositoryProvider = Provider<HomeDiscoveryRepository>(
  (ref) => throw StateError(
    'homeDiscoveryRepositoryProvider must be overridden by the application',
  ),
);
