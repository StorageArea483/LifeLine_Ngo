import 'package:flutter_riverpod/legacy.dart';

class NgoLoginNotifier extends StateNotifier<NgoLoginState> {
  NgoLoginNotifier()
    : super(const NgoLoginState(obscurePassword: false, isLoading: false));

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }
}

class NgoLoginState {
  final bool obscurePassword;
  final bool isLoading;

  const NgoLoginState({this.obscurePassword = false, this.isLoading = false});

  NgoLoginState copyWith({bool? obscurePassword, bool? isLoading}) {
    return NgoLoginState(
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final ngoLoginProvider =
    StateNotifierProvider.autoDispose<NgoLoginNotifier, NgoLoginState>(
      (ref) => NgoLoginNotifier(),
    );
