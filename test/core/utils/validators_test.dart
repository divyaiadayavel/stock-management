import 'package:flutter_test/flutter_test.dart';
import 'package:stock_management/core/utils/validators.dart'; // Adjust path if your app name is different

void main() {
  group('Validators Test Suite', () {
    // --- EMAIL TESTS ---
    test('TC_VAL_001: Email empty check', () {
      expect(Validators.validateEmail(''), equals('Email is required'));
      expect(Validators.validateEmail('   '), equals('Email is required'));
    });

    test('TC_VAL_002: Email missing @ symbol', () {
      expect(
        Validators.validateEmail('userdomain.com'),
        equals('Enter a valid email address'),
      );
    });

    test('TC_VAL_003: Email missing TLD', () {
      expect(
        Validators.validateEmail('user@domain'),
        equals('Enter a valid email address'),
      );
    });

    test('TC_VAL_004: Email with spaces around valid format', () {
      expect(Validators.validateEmail('  test@example.com  '), isNull);
    });

    test('TC_VAL_005: Valid Email check', () {
      expect(Validators.validateEmail('admin@company.org'), isNull);
    });

    // --- PASSWORD TESTS ---
    test('TC_VAL_006: Password empty check', () {
      expect(Validators.validatePassword(''), equals('Password is required'));
    });

    test('TC_VAL_007: Password less than 6 characters', () {
      expect(
        Validators.validatePassword('12345'),
        equals('Password must be at least 6 characters'),
      );
    });

    test('TC_VAL_008: Valid password check', () {
      expect(Validators.validatePassword('123456'), isNull);
    });

    // --- NAME TESTS ---
    test('TC_VAL_009: Name empty check', () {
      expect(Validators.validateName(''), equals('Name is required'));
    });

    test('TC_VAL_010: Name less than 3 characters', () {
      expect(
        Validators.validateName('Al'),
        equals('Name must be at least 3 characters'),
      );
    });

    test('TC_VAL_011: Valid Name check', () {
      expect(Validators.validateName('Divya'), isNull);
    });

    // --- REGISTER PASSWORD TESTS ---
    test('TC_VAL_012: Register password missing uppercase', () {
      expect(
        Validators.validateRegisterPassword('pass123'),
        equals('Must contain at least 1 uppercase letter'),
      );
    });

    test('TC_VAL_013: Register password missing number', () {
      expect(
        Validators.validateRegisterPassword('Password'),
        equals('Must contain at least 1 number'),
      );
    });

    test('TC_VAL_014: Register password valid', () {
      expect(Validators.validateRegisterPassword('Pass123'), isNull);
    });

    // --- CONFIRM PASSWORD TESTS ---
    test('TC_VAL_015: Confirm password empty', () {
      expect(
        Validators.validateConfirmPassword('Pass123', ''),
        equals('Confirm password is required'),
      );
    });

    test('TC_VAL_016: Confirm password mismatch', () {
      expect(
        Validators.validateConfirmPassword('Pass123', 'Pass456'),
        equals('Passwords do not match'),
      );
    });

    test('TC_VAL_017: Confirm password match', () {
      expect(Validators.validateConfirmPassword('Pass123', 'Pass123'), isNull);
    });

    // --- OTP TESTS ---
    test('TC_VAL_018: OTP empty', () {
      expect(Validators.validateOtp(''), equals('OTP is required'));
    });

    test('TC_VAL_019: OTP invalid length', () {
      expect(Validators.validateOtp('12345'), equals('OTP must be 6 digits'));
    });

    test('TC_VAL_020: Valid OTP check', () {
      expect(Validators.validateOtp('123456'), isNull);
    });
  });
}
