import 'package:roamly_app/src/features/assistant/domain/entities/assistant_request.dart';
import 'package:uuid/uuid.dart';

typedef AssistantIdGenerator = String Function();
typedef AssistantRequestClock = DateTime Function();

final class AssistantRequestFactory {
  AssistantRequestFactory({
    AssistantIdGenerator? idGenerator,
    AssistantRequestClock? clock,
  }) : _generatorId = idGenerator ?? const Uuid().v4,
       _clock = clock ?? DateTime.now;
  final AssistantIdGenerator _generatorId;
  final AssistantRequestClock _clock;
  AssistantRequest create({
    required String message,
    String locale = 'en',
    String? conversationLocalId,
    String? conversationId,
    String? tripId,
  }) {
    return AssistantRequest(
      conversationLocalId: conversationLocalId ?? _generatorId(),
      clientMessageId: _generatorId(),
      conversationId: conversationId,
      tripId: tripId,
      message: message,
      locale: locale,
      createdAt: _clock(),
    );
  }
}
