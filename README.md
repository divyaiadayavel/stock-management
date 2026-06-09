# stock_management

A new Flutter project.

## Auth and Role Access

The app now uses a single Riverpod auth controller for login state:

- Existing local admin login still works through SQLite `DBHelper.login()`.
- Staff users created in **Settings > User Roles & Permissions** log in through PHP at `settings/staff_login.php`.
- The active user is stored in `AuthState.user` with `name`, `email`, `role`, `source`, and active status fields.
- Logout is available from **Settings > Account > Logout** and clears the Riverpod auth state.

Temporary access mode is controlled from:

```dart
lib/features/auth/presentation/controllers/access_policy.dart
```

`RoleAccessPolicy.allowAllRolesTemporarily` is currently `true`, so every role can open every screen. When role restrictions are needed, set it to `false` and update the role-to-feature mapping in the same file.

Flutter screens should use the auth access layer instead of checking roles manually:

- `access_provider.dart` exposes the current user's allowed features through Riverpod.
- `AccessGuard` wraps protected screens and shows a restricted-access view when a role is blocked.
- `MainNavigationScreen` checks the same provider before opening tabs or billing.

### PHP Staff Login Endpoint

Deploy this file to the backend matching `ApiConfig.baseUrl`:

```text
backend/settings/staff_login.php -> public_html/settings/staff_login.php
```

Create the database table with:

```text
backend/database/staff_access_schema.sql
```

Create the PHP DB config from:

```text
backend/config/database.example.php -> public_html/config/database.php
```

Important for your existing `settings/save_settings.php`: when Staff Access saves a password, store it in `staff_users.password_hash` using:

```php
password_hash($plainPassword, PASSWORD_DEFAULT)
```

Use this helper as the staff section for your existing `save_settings.php`:

```text
backend/settings/save_settings_staff_section.example.php
```

It matches the Flutter payload keys: `staff`, `staff_delete_id`, and `staff_status`.

`staff_login.php` verifies that hash, blocks inactive staff users, and returns only safe user fields.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
