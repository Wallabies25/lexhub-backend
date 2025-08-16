-- 002_create_lawyers.sql
CREATE TABLE lawyer_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    license_number VARCHAR(100) UNIQUE NOT NULL,
    specialty VARCHAR(100),
    verification_status VARCHAR(50) DEFAULT 'pending',
    verification_date TIMESTAMP,
    bio TEXT,
    hourly_rate DECIMAL(10,2)
);