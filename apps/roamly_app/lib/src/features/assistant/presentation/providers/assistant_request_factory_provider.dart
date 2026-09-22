import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/assistant/application/factories/assistant_request_factory.dart';

final assistantRequestFactoryProvider = Provider<AssistantRequestFactory>(
  (ref) => AssistantRequestFactory(),
);
