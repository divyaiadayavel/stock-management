<?php
declare(strict_types=1);

$host = '127.0.0.1';
$dbName = 'stock_management';
$username = 'YOUR_DB_USER';
$password = 'YOUR_DB_PASSWORD';

$dsn = "mysql:host={$host};dbname={$dbName};charset=utf8mb4";

$pdo = new PDO($dsn, $username, $password, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    PDO::ATTR_EMULATE_PREPARES => false,
]);
