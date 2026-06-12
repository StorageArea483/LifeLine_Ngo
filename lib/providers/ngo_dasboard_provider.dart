import 'package:flutter_riverpod/legacy.dart';

class NgoDasboardNotifier extends StateNotifier<NgoDasboardState> {
  NgoDasboardNotifier()
    : super(
        const NgoDasboardState(victims: [], isLoading: true, victimCount: 0),
      );

  void setVictims(List<Map<String, dynamic>> victims) {
    state = state.copyWith(victims: victims);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setVictimCount(int count) {
    state = state.copyWith(victimCount: count);
  }

  void setNotificationCount(int count) {
    state = state.copyWith(notificationCount: count);
  }

  void setRescuerCount(int count) {
    state = state.copyWith(rescuerCount: count);
  }

  void setNgoDocId(String docId) {
    state = state.copyWith(ngoDocId: docId);
  }
}

class NgoDasboardState {
  final List<Map<String, dynamic>> victims;
  final bool isLoading;
  final int victimCount;
  final int notificationCount;
  final int rescuerCount;
  final String? ngoDocId;

  const NgoDasboardState({
    required this.victims,
    required this.isLoading,
    required this.victimCount,
    this.notificationCount = 0,
    this.rescuerCount = 0,
    this.ngoDocId,
  });

  NgoDasboardState copyWith({
    List<Map<String, dynamic>>? victims,
    bool? isLoading,
    int? victimCount,
    int? notificationCount,
    int? rescuerCount,
    String? ngoDocId,
  }) {
    return NgoDasboardState(
      victims: victims ?? this.victims,
      isLoading: isLoading ?? this.isLoading,
      victimCount: victimCount ?? this.victimCount,
      notificationCount: notificationCount ?? this.notificationCount,
      rescuerCount: rescuerCount ?? this.rescuerCount,
      ngoDocId: ngoDocId ?? this.ngoDocId,
    );
  }
}

final ngoDasboardProvider =
    StateNotifierProvider<NgoDasboardNotifier, NgoDasboardState>((ref) {
      return NgoDasboardNotifier();
    });
