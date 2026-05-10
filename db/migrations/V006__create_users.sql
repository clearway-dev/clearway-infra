-- V006: Create users table for JWT-based authentication and RBAC.
-- Roles: 'admin' (full CRUD), 'dispatcher' (read-only + routing).

CREATE TABLE users (
    id              SERIAL PRIMARY KEY,
    email           VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name       VARCHAR(255),
    role            VARCHAR(50)  NOT NULL DEFAULT 'dispatcher',
    is_active       BOOLEAN      NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ  NOT NULL DEFAULT NOW()
);

CREATE INDEX ix_users_email ON users (email);

-- Seed: admin@clearway.cz / admin123
INSERT INTO users (email, hashed_password, full_name, role) VALUES (
    'admin@clearway.cz',
    '$2b$12$4k9Wn16jSkhtkp2XZiTAq.qPkL6eT2kbfJjTXpBgJG8VHDmxczt4C',
    'Ing. Petr Správce',
    'admin'
);

-- Seed: dispecink@hzs-pk.cz / dispatcher123
INSERT INTO users (email, hashed_password, full_name, role) VALUES (
    'dispecink@hzs-pk.cz',
    '$2b$12$WM.5YHxMeqqNHJMoksEtSejkwHTPaxz/sEbLV63qe4skBqqorW0UO',
    'Jana Nováková',
    'dispatcher'
);
