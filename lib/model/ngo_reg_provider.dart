import 'package:flutter_riverpod/legacy.dart';

class NgoRegNotifier extends StateNotifier<NgoRegState> {
  NgoRegNotifier()
    : super(const NgoRegState(selectedProgram: '', isLoading: false));

  void setSelectedProgram(String program) {
    state = state.copyWith(selectedProgram: program);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

class NgoRegState {
  final String selectedProgram;
  final bool isLoading;

  const NgoRegState({this.selectedProgram = '', this.isLoading = false});

  NgoRegState copyWith({String? selectedProgram, bool? isLoading}) {
    return NgoRegState(
      selectedProgram: selectedProgram ?? this.selectedProgram,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final ngoRegProvider = StateNotifierProvider<NgoRegNotifier, NgoRegState>(
  (ref) => NgoRegNotifier(),
);
