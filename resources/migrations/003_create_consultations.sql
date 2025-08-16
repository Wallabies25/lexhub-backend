-- 003_create_consultations.sql
CREATE TABLE consultations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lawyer_id UUID REFERENCES users(id),
    client_id UUID REFERENCES users(id),
    scheduled_at TIMESTAMP NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    status VARCHAR(50) DEFAULT 'scheduled',
    meeting_type VARCHAR(50), -- 'video', 'phone', 'in_person'
    created_at TIMESTAMP DEFAULT NOW()
);