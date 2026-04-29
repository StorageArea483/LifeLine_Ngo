import 'package:flutter_riverpod/legacy.dart';

class NgoDasboardNotifier extends StateNotifier<NgoDasboardState> {
  NgoDasboardNotifier()
    : super(const NgoDasboardState(victims: [], isLoading: true));

  void setVictims(List<Map<String, dynamic>> victims) {
    state = state.copyWith(victims: victims);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

class NgoDasboardState {
  final List<Map<String, dynamic>> victims;
  final bool isLoading;

  const NgoDasboardState({required this.victims, required this.isLoading});

  NgoDasboardState copyWith({
    List<Map<String, dynamic>>? victims,
    bool? isLoading,
  }) {
    return NgoDasboardState(
      victims: victims ?? this.victims,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final ngoDasboardProvider =
    StateNotifierProvider<NgoDasboardNotifier, NgoDasboardState>((ref) {
      return NgoDasboardNotifier();
    });
