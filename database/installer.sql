CREATE DATABASE temp_database CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
CREATE USER 'temp_username'@'localhost' IDENTIFIED BY 'temp_password';
GRANT ALL PRIVILEGES ON *.* TO 'temp_username'@'localhost';
FLUSH PRIVILEGES;
