CREATE DATABASE temp_dbname CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_520_ci;
CREATE USER 'temp_dbuser'@'localhost' IDENTIFIED BY 'temp_dbpass';
GRANT ALL PRIVILEGES ON *.* TO 'temp_dbuser'@'localhost';
FLUSH PRIVILEGES;
