import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/repository_providers.dart';
import '../../../data/models/chat.dart';

final userThreadsStreamProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.watchThreadsForUser(user.id);
});

final threadMessagesStreamProvider = StreamProvider.family.autoDispose<List<ChatMessage>, String>((ref, threadId) {
  final chatRepo = ref.watch(chatRepositoryProvider);
  return chatRepo.watchMessages(threadId);
});
