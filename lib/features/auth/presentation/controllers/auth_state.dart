class AuthState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? user;

  // ✅ ADD THESE
  final String? otp;
  final String? otpEmail;

  AuthState({
    this.isLoading = false,
    this.error,
    this.user,
    this.otp,
    this.otpEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? user,
    String? otp,
    String? otpEmail,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
      otp: otp ?? this.otp,
      otpEmail: otpEmail ?? this.otpEmail,
    );
  }
}
