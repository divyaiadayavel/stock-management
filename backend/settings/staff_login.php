<?php
declare(strict_types=1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Headers: Content-Type, Accept, ngrok-skip-browser-warning');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    respond(false, 'Method not allowed', null, 405);
}

require_once __DIR__ . '/../config/database.php';

if (!isset($pdo) || !$pdo instanceof PDO) {
    respond(false, 'Database connection is not configured', null, 500);
}

$input = json_decode(file_get_contents('php://input'), true);
if (!is_array($input)) {
    respond(false, 'Invalid JSON body', null, 400);
}

$email = strtolower(trim((string)($input['email'] ?? '')));
$password = (string)($input['password'] ?? '');

if ($email === '' || $password === '') {
    respond(false, 'Email and password are required', null, 422);
}

try {
    $stmt = $pdo->prepare('SELECT * FROM staff_users WHERE LOWER(email) = :email LIMIT 1');
    $stmt->execute(['email' => $email]);
    $staff = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$staff) {
        respond(false, 'Invalid email or password', null, 401);
    }

    if (!read_active($staff)) {
        respond(false, 'This staff account is inactive', null, 403);
    }

    $passwordHash = (string)($staff['password_hash'] ?? '');
    $legacyPassword = (string)($staff['password'] ?? '');
    $verified = false;
    $needsRehash = false;

    if ($passwordHash !== '' && password_verify($password, $passwordHash)) {
        $verified = true;
        $needsRehash = password_needs_rehash($passwordHash, PASSWORD_DEFAULT);
    }

    if (!$verified && $legacyPassword !== '' && password_verify($password, $legacyPassword)) {
        $verified = true;
        $needsRehash = password_needs_rehash($legacyPassword, PASSWORD_DEFAULT);
    }

    if (!$verified && $legacyPassword !== '' && hash_equals($legacyPassword, $password)) {
        $verified = true;
        $needsRehash = true;
    }

    if (!$verified) {
        respond(false, 'Invalid email or password', null, 401);
    }

    if ($needsRehash && array_key_exists('password_hash', $staff)) {
        $newHash = password_hash($password, PASSWORD_DEFAULT);
        $update = $pdo->prepare('UPDATE staff_users SET password_hash = :password WHERE id = :id');
        $update->execute(['password' => $newHash, 'id' => $staff['id']]);
    }

    respond(true, 'Login successful', [
        'user' => [
            'id' => (int)$staff['id'],
            'name' => (string)($staff['name'] ?? $staff['full_name'] ?? 'Staff User'),
            'email' => (string)$staff['email'],
            'phone' => (string)($staff['phone'] ?? $staff['phone_number'] ?? ''),
            'role' => (string)($staff['role'] ?? 'staff'),
            'is_active' => read_active($staff),
            'source' => 'staff',
        ],
    ]);
} catch (Throwable $e) {
    respond(false, 'Staff login failed', null, 500);
}

function read_active(array $staff): bool
{
    $value = $staff['is_active'] ?? $staff['isActive'] ?? 1;
    if (is_bool($value)) {
        return $value;
    }
    return in_array(strtolower((string)$value), ['1', 'true', 'yes', 'active'], true);
}

function respond(bool $success, string $message, ?array $data = null, int $status = 200): void
{
    http_response_code($status);
    echo json_encode([
        'success' => $success,
        'message' => $message,
        'data' => $data ?? new stdClass(),
    ]);
    exit;
}
