import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

class RescuerInfoNotifier extends StateNotifier<RescuerInfoState> {
  RescuerInfoNotifier()
    : super(const RescuerInfoState(isLoading: false, rescuers: []));

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setRescuers(List<Map<String, dynamic>> rescuers) {
    if (listEquals(state.rescuers, rescuers)) return;
    state = state.copyWith(rescuers: rescuers);
  }
}

class RescuerInfoState {
  final bool isLoading;
  final List<Map<String, dynamic>> rescuers;

  const RescuerInfoState({this.isLoading = false, this.rescuers = const []});

  RescuerInfoState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? rescuers,
  }) {
    return RescuerInfoState(
      isLoading: isLoading ?? this.isLoading,
      rescuers: rescuers ?? this.rescuers,
    );
  }
}

final rescuerPageProvider =
    StateNotifierProvider.autoDispose<RescuerInfoNotifier, RescuerInfoState>((
      ref,
    ) {
      return RescuerInfoNotifier();
    });
