import 'package:flutter_riverpod/legacy.dart';

// Deterministic chat id between NGO and victim
final ngoChatIdProvider = StateProvider<String?>((ref) => null);

// Loading state while chat initializes
final ngoChatLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);

// Messages for a given chatId
final ngoChatMessagesProvider =
    StateProvider.family<List<Map<String, dynamic>>, String>(
      (ref, chatId) => [],
    );

// Live online/offline status of the victim, keyed by victimId
final victimOnlineStatusProvider = StateProvider.family<bool, String>(
  (ref, victimId) => false,
);
