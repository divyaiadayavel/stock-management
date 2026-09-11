import 'package:flutter_test/flutter_test.dart';
import 'package:stock_management/core/utils/validators.dart';
import 'package:stock_management/features/auth/presentation/controllers/access_policy.dart';
import 'package:stock_management/features/auth/presentation/controllers/auth_state.dart';

void main() {
  group('Consolidated Auth Test Suite', () {
    // --- LOGIN VALIDATION ---
    test('TC_AUTH_001 - TC_AUTH_003: Login Field Validation', () {
      expect(Validators.validateEmail(''), equals('Email is required'));
      expect(
        Validators.validateEmail('userdomain.com'),
        equals('Enter a valid email address'),
      );
      expect(
        Validators.validatePassword('12345'),
        equals('Password must be at least 6 characters'),
      );
    });

    // --- OTP VALIDATION ---
    test('TC_AUTH_010: OTP Length Validation', () {
      expect(Validators.validateOtp('12345'), equals('OTP must be 6 digits'));
      expect(Validators.validateOtp('123456'), isNull);
    });

    // --- PASSWORD RULES (REGISTRATION / RESET) ---
    test('TC_AUTH_015 & TC_AUTH_016: Strong Password Rule Verification', () {
      expect(
        Validators.validateRegisterPassword('pass123'),
        equals('Must contain at least 1 uppercase letter'),
      );
      expect(
        Validators.validateRegisterPassword('Password'),
        equals('Must contain at least 1 number'),
      );
      expect(Validators.validateRegisterPassword('Pass123'), isNull);
    });

    // --- ACCESS POLICY (ROLES & PERMISSIONS) ---
    test('TC_AUTH_017 & TC_AUTH_018: Role Access Control Verification', () {
      // Cashier boundaries
      expect(
        RoleAccessPolicy.canAccess(
          role: 'cashier',
          feature: AppFeature.dashboard,
        ),
        isTrue,
      );
      expect(
        RoleAccessPolicy.canAccess(
          role: 'cashier',
          feature: AppFeature.billing,
        ),
        isTrue,
      );
      expect(
        RoleAccessPolicy.canAccess(
          role: 'cashier',
          feature: AppFeature.reports,
        ),
        isFalse,
      );
      expect(
        RoleAccessPolicy.canAccess(
          role: 'cashier',
          feature: AppFeature.inventory,
        ),
        isFalse,
      );

      // Admin & Manager full access
      expect(RoleAccessPolicy.allowedFeatures('admin').length, equals(5));
      expect(RoleAccessPolicy.allowedFeatures('manager').length, equals(5));
    });

    // --- AUTH STATE & LOGOUT ---
    test('TC_AUTH_019: AuthState management & Logout check', () {
      var state = AuthState(
        user: {
          'id': 1,
          'name': 'John Staff',
          'email': 'john@store.com',
          'role': 'cashier',
          'source': 'staff',
        },
      );

      expect(state.isLoggedIn, isTrue);
      expect(state.currentRole, equals('cashier'));

      // Simulate Logout
      state = AuthState();
      expect(state.isLoggedIn, isFalse);
      expect(state.user, isNull);
    });
  });
}
