import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

class VictimInfoNotifier extends StateNotifier<VictimInfoState> {
  VictimInfoNotifier()
    : super(const VictimInfoState(isLoading: false, victims: []));

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setVictims(List<Map<String, dynamic>> victims) {
    if (listEquals(state.victims, victims)) return;
    state = state.copyWith(victims: victims);
  }
}

class VictimInfoState {
  final bool isLoading;
  final List<Map<String, dynamic>> victims;

  const VictimInfoState({this.isLoading = false, this.victims = const []});

  VictimInfoState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? victims,
  }) {
    return VictimInfoState(
      isLoading: isLoading ?? this.isLoading,
      victims: victims ?? this.victims,
    );
  }
}

final victimPageProvider =
    StateNotifierProvider.autoDispose<VictimInfoNotifier, VictimInfoState>((
      ref,
    ) {
      return VictimInfoNotifier();
    });
