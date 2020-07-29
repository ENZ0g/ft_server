CREATE DATABASE testdb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'testuser'@'localhost' IDENTIFIED BY 'test_password';
GRANT ALL ON testdb.* TO 'testuser'@'localhost';
FLUSH PRIVILEGES;
EXIT