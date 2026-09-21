import 'package:roamly_app/src/features/assistant/data/database/assistant_database.dart';
import 'package:roamly_app/src/features/assistant/data/repositories/default_assistant_repository.dart';
import 'package:roamly_app/src/features/assistant/data/services/default_assistant_heartbeat_coordinator.dart';
import 'package:roamly_app/src/features/assistant/data/services/default_assistant_realtime_session.dart';
import 'package:roamly_app/src/features/assistant/data/sources/default_assistant_socket_data_source.dart';
import 'package:roamly_app/src/features/assistant/data/sources/drift_assistant_local_data_source.dart';
import 'package:roamly_app/src/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:roamly_logging/roamly_logging.dart';
import 'package:roamly_networking/roamly_networking.dart';

/// Application-scoped dependencies owned by the Assistant feature.
///
/// Call [dispose] when the authenticated user changes or the application
/// container disposes this feature.
final class AssistantDependencies {
  final AssistantRepository _repository;
  final AssistantDatabase _database;

  AssistantDependencies({
    required AssistantRepository repository,
    required AssistantDatabase database,
  }) : _database = database,
       _repository = repository;

  Future<void>? _disposeFuture;
  AssistantRepository get repository => _repository;
  Future<void> dispose() {
    return _disposeFuture ??= _dispose();
  }

  Future<void> _dispose() async {
    try {
      await _repository.dispose();
    } finally {
      await _database.close();
    }
  }
}

/// Composition root for the Assistant feature.
///
/// This is the only place that knows the feature's concrete data sources,
/// WebSocket transport, heartbeat coordinator, database, and repository.
abstract final class AssistantModule {
  static AssistantDependencies create({
    required Uri websocketUri,
    required AccessTokenProvider accessTokenProvider,
    required String ownerId,
    required RoamlyLogger logger,
    WebsocketTransport transport = const IoWebSocketTransport(),
    ReconnectPolicy? reconnectPolicy,
  }) {
    final featureLogger = logger.child('assistant');
    final database = AssistantDatabase();
    final localDataSource = DriftAssistantLocalDataSource(
      database: database,
      ownerId: ownerId,
    );
    final manager = WebsocketManager(
      transport: transport,
      uri: websocketUri,
      headersProvider: () => _authorizationHeaders(accessTokenProvider),
      reconnectPolicy: reconnectPolicy,
      logger: featureLogger.child('network'),
    );
    final socketDataSource = DefaultAssistantSocketDataSource(manager: manager);
    final heartbeatCoordinator = DefaultAssistantHeartbeatCoordinator(
      dataSource: socketDataSource,
    );
    final realtimeSession = DefaultAssistantRealtimeSession(
      socketDataSource: socketDataSource,
      heartbeatCoordinator: heartbeatCoordinator,
    );
    final repository = DefaultAssistantRepository(
      realtimeSession: realtimeSession,
      localDataSource: localDataSource,
      logger: featureLogger,
    );
    return AssistantDependencies(repository: repository, database: database);
  }

  static Future<Map<String, String>> _authorizationHeaders(
    AccessTokenProvider accessTokenProvider,
  ) async {
    final accessToken = (await accessTokenProvider.readAccessToken())?.trim();
    if (accessToken == null || accessToken.isEmpty) {
      throw WebSocketFailure(kind: WebSocketFailureKind.unauthorized);
    }
    return <String, String>{'Authorization': 'Bearer $accessToken'};
  }
}
