import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/repositories/preference_repository.dart';

/// Provides preference operations to presentation controllers.
///
/// The application composition root must supply the implementation.
final preferenceRepositoryProvider = Provider<PreferenceRepository>(
  (ref) => throw StateError(
    'preferenceRepositoryProvider must be overridden by the application',
  ),
);
