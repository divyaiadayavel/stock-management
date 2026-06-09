# Auth, Staff Access, and Role Access Status

## Current Status

The app now has one Riverpod-based auth flow in progress for both existing local admin login and PHP-backed staff login.

Current login behavior:

- Existing local admin login still works through SQLite in `DBHelper.login()`.
- Staff users created from Settings > Staff Access are intended to login through PHP using `settings/staff_login.php`.
- The logged-in user is stored in Riverpod through `authControllerProvider`.
- Logout is available in Settings and clears auth state before returning to Login.
- Role-based access is currently wired in temporary all-access mode, so every role can access every main screen for now.

Temporary access switch:

- File: `lib/features/auth/presentation/controllers/access_policy.dart`
- Current value: `RoleAccessPolicy.allowAllRolesTemporarily = true`
- Meaning: Admin, Manager, Cashier, Salesperson, Inventory Staff, and custom roles can open all screens.

## Main Flutter Files

### Auth

- `lib/features/auth/presentation/controllers/auth_controller.dart`
  - Main Riverpod auth controller.
  - First checks local SQLite admin login using `DBHelper.login()`.
  - If local login fails, calls PHP endpoint `settings/staff_login.php`.
  - Stores logged-in user in `AuthState`.

- `lib/features/auth/presentation/controllers/auth_state.dart`
  - Holds auth state: loading, error, user, OTP.
  - Added helpers:
    - `isLoggedIn`
    - `currentRole`
    - `displayName`
    - `email`
    - `isStaffUser`

- `lib/features/auth/presentation/screens/login_screen.dart`
  - Login UI now uses `authControllerProvider.notifier.login(...)`.
  - Password validation is relaxed to 6 characters to match Staff Access user creation.
  - Existing branding load remains, with safe fallback if local DB is unavailable.

### Role Access

- `lib/features/auth/presentation/controllers/access_policy.dart`
  - Central role-to-feature policy.
  - Defines app features:
    - dashboard
    - products
    - billing
    - suppliers
    - settings
  - Currently allows all roles because temporary mode is enabled.

- `lib/features/auth/presentation/providers/access_provider.dart`
  - Riverpod provider for current user's allowed features.
  - Screens can check access without reading raw role strings manually.

- `lib/features/auth/presentation/widgets/access_guard.dart`
  - Reusable widget to protect screens.
  - Shows restricted access UI if a role is blocked later.

### Navigation

- `lib/features/dashboard/presentation/screens/main_navigation.dart`
  - Main tabs now use the access provider.
  - Billing button also checks access.
  - Because temporary all-access is enabled, all tabs are available now.

### Settings / Staff Access

- `lib/features/settings/presentation/screens/settings_screen.dart`
  - Added Account section.
  - Added Logout button.
  - Shows current user display name and role.

- `lib/features/settings/presentation/screens/roles_permissions_screen.dart`
  - Staff Access list screen.
  - Shows staff users, active/inactive status, role guide, edit/delete/status actions.
  - Role guide uses the same access policy summary.

- `lib/features/settings/presentation/screens/staff_user_form_screen.dart`
  - Add/Edit staff user form.
  - Saves name, email, phone, role, password, active status.

- `lib/features/settings/presentation/providers/settings_provider.dart`
  - Riverpod settings/staff controller.
  - Handles staff add/update/delete/status reloads.

- `lib/features/settings/data/datasources/settings_remote_datasource.dart`
  - Calls PHP settings endpoints.
  - Staff save payload keys:
    - `staff`
    - `staff_delete_id`
    - `staff_status`

### API Config

- `lib/core/network/api_config.dart`
  - Central backend base URL and JSON headers.
  - Used by settings API and staff login API.

## Backend / PHP Files Added

- `backend/config/database.example.php`
  - Example PDO database connection file.
  - Copy to server as:
    - `public_html/config/database.php`

- `backend/database/staff_access_schema.sql`
  - SQL table for staff users.
  - Creates `staff_users` table with:
    - `id`
    - `user_id`
    - `name`
    - `email`
    - `phone`
    - `role`
    - `password_hash`
    - `is_active`
    - timestamps

- `backend/settings/staff_login.php`
  - PHP endpoint for staff login.
  - Copy to server as:
    - `public_html/settings/staff_login.php`
  - Expects request:
    ```json
    {
      "email": "staff@example.com",
      "password": "password"
    }
    ```
  - Verifies `password_hash`.
  - Blocks inactive users.
  - Returns safe staff user fields only.

- `backend/settings/save_settings_staff_section.example.php`
  - Example staff save helper code for your existing `settings/save_settings.php`.
  - Handles:
    - add/update staff
    - delete staff
    - active/inactive status
  - Important: hashes plain password using:
    ```php
    password_hash($password, PASSWORD_DEFAULT)
    ```

## Database Setup Required

1. Create database, for example:
   - `stock_management`

2. Import:
   - `backend/database/staff_access_schema.sql`

3. Copy:
   - From: `backend/config/database.example.php`
   - To server: `public_html/config/database.php`

4. Edit DB credentials in:
   - `public_html/config/database.php`

5. Ensure your existing:
   - `public_html/settings/save_settings.php`

   saves staff passwords into:
   - `staff_users.password_hash`

   not plain `password`.

6. Deploy:
   - `backend/settings/staff_login.php`
   - to `public_html/settings/staff_login.php`

## Current Backend URL

Configured in:

- `lib/core/network/api_config.dart`

Current base URL is the ngrok/public backend URL. If the backend URL changes, update only this file.

## What Is Working Now

- Local SQLite admin login path is preserved.
- Flutter login screen uses Riverpod auth controller.
- Staff login Flutter call is ready.
- Staff Access screen can create/update staff payloads.
- Logout button exists in Settings.
- Temporary all-role/all-screen access is active.
- Role access policy is centralized for future changes.

## What Still Needs To Be Done On PHP Server

1. Create/import `staff_users` table.
2. Copy `database.php` config to server.
3. Deploy `staff_login.php`.
4. Update existing `save_settings.php` staff save logic to hash passwords into `password_hash`.
5. Test creating a staff user from app.
6. Test logging in with that staff email/password.

## Later: Real Role Restrictions

When temporary access is no longer needed:

1. Open:
   - `lib/features/auth/presentation/controllers/access_policy.dart`

2. Change:
   ```dart
   static const bool allowAllRolesTemporarily = true;
   ```

   to:

   ```dart
   static const bool allowAllRolesTemporarily = false;
   ```

3. Edit `_roleFeatureMap` in the same file.

Example current planned mapping:

- Admin: all screens
- Manager: all screens
- Cashier: dashboard, billing
- Salesperson: dashboard, billing
- Inventory Staff: dashboard, products, suppliers

## Verification Already Run

Targeted Flutter checks passed:

- Auth/access analyzer passed.
- Staff access analyzer passed.
- Auth access tests passed.
- Login smoke test passed.

PHP syntax check was not run because PHP CLI is not installed on this machine.

## Important Note

There are many existing unrelated analyzer warnings in older modules such as products, sales, suppliers, and `settingsoff`. They are not part of the current auth/staff-access work.
