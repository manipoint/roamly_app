import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_conversation.dart';
import 'package:roamly_app/src/features/assistant/domain/entities/assistant_message.dart';
import 'package:roamly_app/src/features/assistant/domain/policies/assistant_policy.dart';
import 'package:roamly_app/src/features/assistant/presentation/providers/assistant_dependency_providers.dart';

final assistantConversationsProvider =
    StreamProvider.autoDispose<List<AssistantConversation>>(((ref) {
      final repository = ref.watch(assistantRepositoryProvider);
      return repository.watchConversations(
        limit: AssistantPolicy.defaultConversationsLimit,
      );
    }));

final assistantRecentMessagesProvider = StreamProvider.autoDispose
    .family<List<AssistantMessage>, String>((ref, conversationLocalId) {
      final repository = ref.watch(assistantRepositoryProvider);
      return repository.watchMessages(
        conversationLocalId: conversationLocalId,
        limit: AssistantPolicy.defaultMessagesLimit,
      );
    });
