-- Additional tables for LexHub backend

-- Add columns to lawyers table for ratings and hourly rate
ALTER TABLE lawyers ADD COLUMN rating FLOAT DEFAULT 0.0;
ALTER TABLE lawyers ADD COLUMN review_count INT DEFAULT 0;
ALTER TABLE lawyers ADD COLUMN hourly_rate DECIMAL(10,2) DEFAULT 0.00;

-- Create consultations table
CREATE TABLE IF NOT EXISTS consultations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    lawyer_id INT NOT NULL,
    consultation_date VARCHAR(20) NOT NULL,
    consultation_time VARCHAR(20) NOT NULL,
    topic VARCHAR(255) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (lawyer_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create reviews table
CREATE TABLE IF NOT EXISTS reviews (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    lawyer_id INT NOT NULL,
    consultation_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (lawyer_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (consultation_id) REFERENCES consultations(id) ON DELETE CASCADE
);

-- Sample data for lawyers
INSERT INTO users (name, email, password, user_type) VALUES
    ('Dr. Priya Wickramasinghe', 'priya@lexhub.lk', '$2a$10$3yoQNgY6HW/VtQiXDpg1BOp4zSLcSKJj8Y3dCGzlV9JRYwV1y56Nm', 'lawyer'),
    ('Rohan Fernando', 'rohan@lexhub.lk', '$2a$10$3yoQNgY6HW/VtQiXDpg1BOp4zSLcSKJj8Y3dCGzlV9JRYwV1y56Nm', 'lawyer'),
    ('Kamala Rajapaksa', 'kamala@lexhub.lk', '$2a$10$3yoQNgY6HW/VtQiXDpg1BOp4zSLcSKJj8Y3dCGzlV9JRYwV1y56Nm', 'lawyer');

-- Sample lawyer details
INSERT INTO lawyers (user_id, phone, license_number, specialty, rating, review_count, hourly_rate) VALUES
    ((SELECT id FROM users WHERE email = 'priya@lexhub.lk'), '+94765551234', 'SL-IP-0023', 'IP Attorney', 4.9, 127, 25000.00),
    ((SELECT id FROM users WHERE email = 'rohan@lexhub.lk'), '+94712345678', 'SL-IP-0045', 'Patent Attorney', 4.8, 89, 20000.00),
    ((SELECT id FROM users WHERE email = 'kamala@lexhub.lk'), '+94773334444', 'SL-IP-0078', 'Copyright Attorney', 4.7, 56, 18000.00);
