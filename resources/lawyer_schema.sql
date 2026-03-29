-- SQL Script for LexHub Database Tables (FastAPI Version)

-- Create users table
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    user_type ENUM('user', 'lawyer', 'admin') DEFAULT 'user',
    joined_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    profile_picture VARCHAR(500),
    bio TEXT
);

-- Create lawyers table
CREATE TABLE IF NOT EXISTS lawyers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE,
    phone VARCHAR(50),
    license_number VARCHAR(100),
    specialty VARCHAR(255),
    cases_handled INT DEFAULT 0,
    success_rate VARCHAR(10),
    education VARCHAR(255),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create consultations table
CREATE TABLE IF NOT EXISTS consultations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    lawyer_id INT,
    status VARCHAR(50) DEFAULT 'pending',
    consultation_date DATE NOT NULL,
    consultation_time VARCHAR(20) NOT NULL,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (lawyer_id) REFERENCES lawyers(id) ON DELETE CASCADE
);
