import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/app/roamly_app.dart';
import 'package:roamly_app/src/config/app_config.dart';
import 'package:roamly_auth/roamly_auth.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final appConfig = AppConfig.fromEnvironment();
  final authDependencies = AuthModule.create(apiConfig: appConfig.apiConfig);

  runApp(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authDependencies.authRepository,
        ),
        deviceIdentityProvider.overrideWithValue(
          authDependencies.deviceIdentity,
        ),
      ],

      child: const RoamlyApp(),
    ),
  );
}
