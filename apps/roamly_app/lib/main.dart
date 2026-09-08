import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/app/roamly_app.dart';
import 'package:roamly_app/src/config/app_config.dart';
import 'package:roamly_app/src/features/preferences/composition/preference_module.dart';
import 'package:roamly_app/src/features/preferences/presentation/providers/preference_dependency_providers.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_logging/roamly_logging.dart';
import 'package:roamly_networking/roamly_networking.dart';

void main() {
  final logger = RoamlyLogger(
    name: 'roamly',
    sink: const DeveloperLogSink(),
    minimumLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
  );

  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    logger.fatal(
      'Unhandled Flutter framework error',
      fields: {'error_type': details.exception.runtimeType.toString()},
      stackTrace: details.stack,
    );
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    logger.fatal(
      'Unhandled root isolate error',
      fields: {'error_type': error.runtimeType.toString()},
      stackTrace: stackTrace,
    );
    return false;
  };

  final appConfig = AppConfig.fromEnvironment();
  final authLogger = logger.child('auth');
  final authDependencies = AuthModule.create(
    apiConfig: appConfig.apiConfig,
    logger: authLogger,
  );
  final preferenceRequestExecutor = DefaultApiRequestExecutor(
    failureMapper: DefaultDioFailureMapper(),
    logger: logger.child('preferences.network'),
  );

  logger.info(
    'Application configured',
    fields: {'api_base_uri': appConfig.apiConfig.baseUri},
  );

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authDependencies.authRepository,
        ),
        deviceIdentityProvider.overrideWithValue(
          authDependencies.deviceIdentity,
        ),
        authLoggerProvider.overrideWithValue(authLogger),
        preferenceRepositoryProvider.overrideWith((ref) {
          return PreferenceModule.create(
            authenticatedClient: authDependencies.authenticatedApiClient,
            requestExecutor: preferenceRequestExecutor,
          );
        }),
        locationResolutionRepositoryProvider.overrideWith((ref) {
          return PreferenceModule.createLocationResolutionRepository(
            authenticatedClient: authDependencies.authenticatedApiClient,
            requestExecutor: preferenceRequestExecutor,
          );
        }),
      ],
      child: const RoamlyApp(),
    ),
  );
}
