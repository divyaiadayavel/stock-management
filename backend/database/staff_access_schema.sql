CREATE TABLE IF NOT EXISTS staff_users (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id INT UNSIGNED NOT NULL DEFAULT 1,
  name VARCHAR(120) NOT NULL,
  email VARCHAR(190) NOT NULL,
  phone VARCHAR(30) NOT NULL DEFAULT '',
  role VARCHAR(60) NOT NULL DEFAULT 'Cashier',
  password_hash VARCHAR(255) NOT NULL,
  is_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY staff_users_email_unique (email),
  KEY staff_users_user_id_index (user_id),
  KEY staff_users_role_index (role),
  KEY staff_users_active_index (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
