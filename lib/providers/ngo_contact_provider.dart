import 'package:flutter_riverpod/legacy.dart';

final victimContactLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

final assignedVictimsProvider =
    StateProvider.autoDispose<List<Map<String, dynamic>>>((ref) => []);

final assignedRescuersProvider =
    StateProvider.autoDispose<List<Map<String, dynamic>>>((ref) => []);
