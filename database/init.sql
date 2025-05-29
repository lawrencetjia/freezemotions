-- FreezeMotions Database Schema
CREATE DATABASE IF NOT EXISTS freezemotions;
USE freezemotions;

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    display_name VARCHAR(150),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE albums (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    is_public BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE images (
    id INT AUTO_INCREMENT PRIMARY KEY,
    album_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    title VARCHAR(255),
    file_path VARCHAR(500) NOT NULL,
    file_size INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (album_id) REFERENCES albums(id)
);

INSERT INTO users (username, email, password_hash, display_name) VALUES
('admin', 'admin@freezemotions.com', 'dummy_hash', 'Administrator');

INSERT INTO albums (user_id, title, description) VALUES
(1, 'Sample Album', 'Ein Beispiel-Album zum Testen');
