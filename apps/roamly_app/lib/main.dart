import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/app/roamly_app.dart';
import 'package:roamly_app/src/config/app_config.dart';
import 'package:roamly_auth/roamly_auth.dart';
import 'package:roamly_logging/roamly_logging.dart';

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
      ],

      child: const RoamlyApp(),
    ),
  );
}
