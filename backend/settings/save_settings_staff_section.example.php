<?php
declare(strict_types=1);

/*
 * Copy these staff blocks into your existing settings/save_settings.php.
 * Flutter sends:
 * - {"staff": {...}} for add/update
 * - {"staff_delete_id": 1} for delete
 * - {"staff_status": {"id": 1, "isActive": true}} for active/inactive
 */

function save_staff_user(PDO $pdo, array $staff, int $userId = 1): void
{
    $id = isset($staff['id']) ? (int)$staff['id'] : null;
    $name = trim((string)($staff['name'] ?? ''));
    $email = strtolower(trim((string)($staff['email'] ?? '')));
    $phone = trim((string)($staff['phone'] ?? ''));
    $role = trim((string)($staff['role'] ?? 'Cashier'));
    $password = (string)($staff['password'] ?? '');
    $isActive = read_bool($staff['isActive'] ?? $staff['is_active'] ?? true) ? 1 : 0;

    if ($name === '' || $email === '' || $phone === '' || $role === '') {
        throw new InvalidArgumentException('Name, email, phone, and role are required');
    }

    if ($id === null && $password === '') {
        throw new InvalidArgumentException('Password is required');
    }

    if ($id === null) {
        $stmt = $pdo->prepare(
            'INSERT INTO staff_users (user_id, name, email, phone, role, password_hash, is_active)
             VALUES (:user_id, :name, :email, :phone, :role, :password_hash, :is_active)'
        );
        $stmt->execute([
            'user_id' => $userId,
            'name' => $name,
            'email' => $email,
            'phone' => $phone,
            'role' => $role,
            'password_hash' => password_hash($password, PASSWORD_DEFAULT),
            'is_active' => $isActive,
        ]);
        return;
    }

    $params = [
        'id' => $id,
        'user_id' => $userId,
        'name' => $name,
        'email' => $email,
        'phone' => $phone,
        'role' => $role,
        'is_active' => $isActive,
    ];

    $passwordSql = '';
    if ($password !== '') {
        $passwordSql = ', password_hash = :password_hash';
        $params['password_hash'] = password_hash($password, PASSWORD_DEFAULT);
    }

    $stmt = $pdo->prepare(
        "UPDATE staff_users
         SET name = :name, email = :email, phone = :phone, role = :role, is_active = :is_active{$passwordSql}
         WHERE id = :id AND user_id = :user_id"
    );
    $stmt->execute($params);
}

function delete_staff_user(PDO $pdo, int $staffId, int $userId = 1): void
{
    $stmt = $pdo->prepare('DELETE FROM staff_users WHERE id = :id AND user_id = :user_id');
    $stmt->execute(['id' => $staffId, 'user_id' => $userId]);
}

function set_staff_status(PDO $pdo, int $staffId, bool $isActive, int $userId = 1): void
{
    $stmt = $pdo->prepare(
        'UPDATE staff_users SET is_active = :is_active WHERE id = :id AND user_id = :user_id'
    );
    $stmt->execute([
        'is_active' => $isActive ? 1 : 0,
        'id' => $staffId,
        'user_id' => $userId,
    ]);
}

function read_bool(mixed $value): bool
{
    if (is_bool($value)) {
        return $value;
    }
    return in_array(strtolower((string)$value), ['1', 'true', 'yes', 'active'], true);
}
