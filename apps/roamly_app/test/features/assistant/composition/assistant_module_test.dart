import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roamly_app/src/features/assistant/composition/assistant_module.dart';
import 'package:roamly_logging/roamly_logging.dart';
import 'package:roamly_networking/roamly_networking.dart';

final class _FakeAccessTokenProvider implements AccessTokenProvider {
  _FakeAccessTokenProvider(this.token);

  final String? token;
  int reads = 0;

  @override
  Future<String?> readAccessToken() async {
    reads++;
    return token;
  }
}

final class _FakeWebSocketConnection implements WebSocketConnection {
  final StreamController<String> _messages = StreamController<String>();
  final Completer<WebSocketCloseInfo> _closed = Completer<WebSocketCloseInfo>();

  int closeCalls = 0;

  @override
  Future<WebSocketCloseInfo> get closed => _closed.future;

  @override
  Stream<String> get message => _messages.stream;

  @override
  Future<void> close({int code = 1000, String? reason}) async {
    closeCalls++;
    if (!_closed.isCompleted) {
      _closed.complete(WebSocketCloseInfo(code: code, reason: reason));
      await _messages.close();
    }
  }

  @override
  Future<void> send(String message) async {}
}

final class _FakeWebSocketTransport implements WebsocketTransport {
  final connection = _FakeWebSocketConnection();
  final headers = <Map<String, String>>[];
  final uris = <Uri>[];

  @override
  Future<WebSocketConnection> connect({
    required Uri uri,
    required Duration connectTimeout,
    Map<String, String> headers = const {},
  }) async {
    uris.add(uri);
    this.headers.add(Map<String, String>.of(headers));
    return connection;
  }
}

final class _RecordingLogSink implements LogSink {
  final records = <LogRecord>[];

  @override
  void write(LogRecord record) => records.add(record);
}

Future<void> _eventually(bool Function() predicate) async {
  final deadline = DateTime.now().add(const Duration(seconds: 2));
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition timed out.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory databaseDirectory;

  setUpAll(() async {
    databaseDirectory = await Directory.systemTemp.createTemp(
      'roamly-assistant-module-test-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProviderChannel,
          (_) async => databaseDirectory.path,
        );
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    await databaseDirectory.delete(recursive: true);
  });

  test(
    'connects with a fresh trimmed bearer token and disposes once',
    () async {
      final transport = _FakeWebSocketTransport();
      final tokenProvider = _FakeAccessTokenProvider('  access-token  ');
      final dependencies = AssistantModule.create(
        websocketUri: Uri.parse('wss://example.com/ws/travel'),
        accessTokenProvider: tokenProvider,
        ownerId: 'assistant-module-user',
        logger: RoamlyLogger(
          name: 'test.assistant.module',
          sink: const NoopLogSink(),
        ),
        transport: transport,
      );

      dependencies.repository.connect();
      await _eventually(() => transport.uris.isNotEmpty);

      expect(transport.uris.single, Uri.parse('wss://example.com/ws/travel'));
      expect(transport.headers.single, <String, String>{
        'Authorization': 'Bearer access-token',
      });
      expect(tokenProvider.reads, 1);

      await dependencies.dispose();
      await dependencies.dispose();

      expect(transport.connection.closeCalls, 1);
      expect(dependencies.repository.connect, throwsStateError);
    },
  );

  test(
    'rejects a connection attempt when the access token is absent',
    () async {
      final transport = _FakeWebSocketTransport();
      final tokenProvider = _FakeAccessTokenProvider('   ');
      final sink = _RecordingLogSink();
      final dependencies = AssistantModule.create(
        websocketUri: Uri.parse('wss://example.com/ws/travel'),
        accessTokenProvider: tokenProvider,
        ownerId: 'assistant-module-user',
        logger: RoamlyLogger(name: 'test.assistant.module', sink: sink),
        transport: transport,
      );

      dependencies.repository.connect();
      await _eventually(
        () => sink.records.any(
          (record) =>
              record.fields['failure_kind'] ==
              WebSocketFailureKind.unauthorized.name,
        ),
      );

      expect(tokenProvider.reads, 1);
      expect(transport.uris, isEmpty);

      await dependencies.dispose();
    },
  );
}
