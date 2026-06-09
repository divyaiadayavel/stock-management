const Object _unset = Object();

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

  bool get isLoggedIn => user != null;

  String get currentRole {
    return user?['role']?.toString().toLowerCase() ?? '';
  }

  String get displayName {
    return user?['name']?.toString() ?? 'User';
  }

  String get email {
    return user?['email']?.toString() ?? '';
  }

  bool get isStaffUser {
    return user?['source']?.toString() == 'staff';
  }

  AuthState copyWith({
    bool? isLoading,
    Object? error = _unset,
    Object? user = _unset,
    Object? otp = _unset,
    Object? otpEmail = _unset,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      user: identical(user, _unset)
          ? this.user
          : user as Map<String, dynamic>?,
      otp: identical(otp, _unset) ? this.otp : otp as String?,
      otpEmail: identical(otpEmail, _unset)
          ? this.otpEmail
          : otpEmail as String?,
    );
  }
}
