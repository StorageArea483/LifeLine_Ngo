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
}

class NgoDasboardState {
  final List<Map<String, dynamic>> victims;
  final bool isLoading;
  final int victimCount;

  const NgoDasboardState({
    required this.victims,
    required this.isLoading,
    required this.victimCount,
  });

  NgoDasboardState copyWith({
    List<Map<String, dynamic>>? victims,
    bool? isLoading,
    int? victimCount,
  }) {
    return NgoDasboardState(
      victims: victims ?? this.victims,
      isLoading: isLoading ?? this.isLoading,
      victimCount: victimCount ?? this.victimCount,
    );
  }
}

final ngoDasboardProvider =
    StateNotifierProvider<NgoDasboardNotifier, NgoDasboardState>((ref) {
      return NgoDasboardNotifier();
    });
