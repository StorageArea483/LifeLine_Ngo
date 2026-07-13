import 'package:flutter_riverpod/legacy.dart';

// Deterministic chat id between NGO and rescuer
final ngoRescuerChatIdProvider = StateProvider<String?>((ref) => null);

// Loading state while chat initializes
final ngoRescuerChatLoadingProvider = StateProvider<bool>((ref) => false);

// Messages for a given chatId
final ngoRescuerChatMessagesProvider =
    StateProvider.family<List<Map<String, dynamic>>, String>(
      (ref, chatId) => [],
    );

// Live online/offline status of the rescuer, keyed by rescuerId
final rescuerOnlineStatusProviderNgo = StateProvider.family<bool, String>(
  (ref, rescuerId) => false,
);
