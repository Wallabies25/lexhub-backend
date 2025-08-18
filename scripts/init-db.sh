#!/bin/bash
set -e

# This script runs the database migrations in order
echo "🚀 Starting LexHub Database Initialization..."

# Note: PostgreSQL Docker initialization handles database creation
# This script runs after PostgreSQL is ready and database is created
echo "✅ PostgreSQL is ready, running migrations..."

# Run migrations in order
echo "🔄 Running database migrations..."

# Migration 001: Create users table
if [ -f "/docker-entrypoint-initdb.d/001_create_users.sql" ]; then
    echo "📝 Running migration 001: Create users table..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/001_create_users.sql
    echo "✅ Migration 001 completed!"
fi

# Migration 002: Create lawyer profiles table
if [ -f "/docker-entrypoint-initdb.d/002_create_lawyers.sql" ]; then
    echo "📝 Running migration 002: Create lawyer profiles table..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/002_create_lawyers.sql
    echo "✅ Migration 002 completed!"
fi

# Migration 003: Create consultations table
if [ -f "/docker-entrypoint-initdb.d/003_create_consultations.sql" ]; then
    echo "📝 Running migration 003: Create consultations table..."
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -f /docker-entrypoint-initdb.d/003_create_consultations.sql
    echo "✅ Migration 003 completed!"
fi

# Insert sample data
echo "📋 Inserting sample data..."
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- Insert sample users
    INSERT INTO users (email, password_hash, name, role, verified) VALUES
    ('admin@lexhub.lk', 'hashed_password_here', 'LexHub Administrator', 'admin', true),
    ('lawyer@example.com', 'hashed_password_here', 'Sample Lawyer', 'lawyer', false),
    ('student@university.edu', 'hashed_password_here', 'Sample Student', 'student', true),
    ('public@example.com', 'hashed_password_here', 'Public User', 'public', true)
    ON CONFLICT (email) DO NOTHING;

    -- Insert sample lawyer profile
    INSERT INTO lawyer_profiles (user_id, license_number, specialty, verification_status)
    SELECT id, 'LK001234', 'Intellectual Property Law', 'pending'
    FROM users WHERE email = 'lawyer@example.com'
    ON CONFLICT (user_id) DO NOTHING;
EOSQL

echo "🎉 Database initialization completed successfully!"
echo "📊 Database is ready for LexHub Backend!"
echo ""
echo "🔗 Connection Details:"
echo "   Host: localhost"
echo "   Port: 5432"
echo "   Database: $POSTGRES_DB"
echo "   Username: $POSTGRES_USER"
echo ""
echo "🌐 pgAdmin URL: http://localhost:5050"
echo "   Email: admin@lexhub.lk"
echo "   Password: admin123"
