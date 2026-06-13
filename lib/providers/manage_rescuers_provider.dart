import 'package:flutter_riverpod/legacy.dart';

class ManageRescuersNotifier extends StateNotifier<ManageRescuersState> {
  ManageRescuersNotifier()
    : super(const ManageRescuersState(isLoading: false, rescuerRequests: []));

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setRescuerRequests(List<Map<String, dynamic>> requests) {
    state = state.copyWith(rescuerRequests: requests);
  }
}

class ManageRescuersState {
  final bool isLoading;
  final List<Map<String, dynamic>> rescuerRequests;

  const ManageRescuersState({
    required this.isLoading,
    required this.rescuerRequests,
  });

  ManageRescuersState copyWith({
    bool? isLoading,
    List<Map<String, dynamic>>? rescuerRequests,
  }) {
    return ManageRescuersState(
      isLoading: isLoading ?? this.isLoading,
      rescuerRequests: rescuerRequests ?? this.rescuerRequests,
    );
  }
}

final manageRescuersProvider =
    StateNotifierProvider.autoDispose<
      ManageRescuersNotifier,
      ManageRescuersState
    >((ref) => ManageRescuersNotifier());
