--db schema

-- 1. USERS

CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,

    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(30),

    password_hash TEXT NOT NULL,

    role VARCHAR(20) NOT NULL DEFAULT 'USER'
        CHECK (role IN ('USER', 'ADMIN')),

    balance NUMERIC(10, 2) NOT NULL DEFAULT 0.00
        CHECK (balance >= 0),

    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (status IN ('ACTIVE', 'BLOCKED')),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. PCS

CREATE TABLE pcs (
    id BIGSERIAL PRIMARY KEY,

    number INTEGER NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,

    cpu VARCHAR(100),
    gpu VARCHAR(100),
    ram VARCHAR(50),
    monitor VARCHAR(100),

    status VARCHAR(20) NOT NULL DEFAULT 'FREE'
        CHECK (
            status IN (
                'FREE',
                'OCCUPIED',
                'RESERVED',
                'MAINTENANCE',
                'OFFLINE'
            )
        ),

    device_token UUID NOT NULL UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TARIFFS

CREATE TABLE tariffs (
    id BIGSERIAL PRIMARY KEY,

    name VARCHAR(100) NOT NULL,

    duration_minutes INTEGER NOT NULL
        CHECK (duration_minutes > 0),

    price NUMERIC(10, 2) NOT NULL
        CHECK (price >= 0),

    description TEXT,

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

--4. BOOKINGS

CREATE TABLE bookings (
    id BIGSERIAL PRIMARY KEY,

    -- Клиент может забронировать ПК без аккаунта
    customer_name VARCHAR(100) NOT NULL,
    customer_phone VARCHAR(30),

    -- Может быть NULL, если бронь создана
    -- только по имени/телефону
    user_id BIGINT NULL,

    pc_id BIGINT NOT NULL,
    tariff_id BIGINT NOT NULL,

    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'RESERVED'
        CHECK (
            status IN (
                'RESERVED',
                'CONFIRMED',
                'CANCELLED',
                'COMPLETED',
                'NO_SHOW'
            )
        ),

    comment TEXT,

    -- Администратор, создавший бронь
    created_by BIGINT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT bookings_time_check
        CHECK (end_time > start_time),

    CONSTRAINT bookings_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE SET NULL,

    CONSTRAINT bookings_pc_fk
        FOREIGN KEY (pc_id)
        REFERENCES pcs(id)
        ON DELETE RESTRICT,

    CONSTRAINT bookings_tariff_fk
        FOREIGN KEY (tariff_id)
        REFERENCES tariffs(id)
        ON DELETE RESTRICT,

    CONSTRAINT bookings_created_by_fk
        FOREIGN KEY (created_by)
        REFERENCES users(id)
        ON DELETE RESTRICT
);

-- 5. SESSIONS

CREATE TABLE sessions (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,
    pc_id BIGINT NOT NULL,

    -- Может быть NULL, если клиент пришёл без предварительной брони
    booking_id BIGINT NULL,

    tariff_id BIGINT NOT NULL,

    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    planned_end_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ NULL,

    status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE'
        CHECK (
            status IN (
                'ACTIVE',
                'COMPLETED',
                'CANCELLED',
                'EXPIRED'
            )
        ),

    total_cost NUMERIC(10, 2) NOT NULL DEFAULT 0.00
        CHECK (total_cost >= 0),

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT sessions_time_check
        CHECK (planned_end_at > started_at),

    CONSTRAINT sessions_ended_time_check
        CHECK (
            ended_at IS NULL
            OR ended_at >= started_at
        ),

    CONSTRAINT sessions_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT sessions_pc_fk
        FOREIGN KEY (pc_id)
        REFERENCES pcs(id)
        ON DELETE RESTRICT,

    CONSTRAINT sessions_booking_fk
        FOREIGN KEY (booking_id)
        REFERENCES bookings(id)
        ON DELETE SET NULL,

    CONSTRAINT sessions_tariff_fk
        FOREIGN KEY (tariff_id)
        REFERENCES tariffs(id)
        ON DELETE RESTRICT
);

-- 6. PAYMENTS

CREATE TABLE payments (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    -- Может быть NULL
    booking_id BIGINT NULL,

    -- Может быть NULL, если платёж не относится к сессии
    session_id BIGINT NULL,

    amount NUMERIC(10, 2) NOT NULL
        CHECK (amount > 0),

    payment_method VARCHAR(20) NOT NULL
        CHECK (
            payment_method IN (
                'BALANCE',
                'CARD',
                'CASH'
            )
        ),

    status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
        CHECK (
            status IN (
                'PENDING',
                'SUCCESS',
                'FAILED',
                'REFUNDED'
            )
        ),

    transaction_id VARCHAR(100) UNIQUE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT payments_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT payments_booking_fk
        FOREIGN KEY (booking_id)
        REFERENCES bookings(id)
        ON DELETE SET NULL,

    CONSTRAINT payments_session_fk
        FOREIGN KEY (session_id)
        REFERENCES sessions(id)
        ON DELETE SET NULL
);

-- 7. BALANCE TRANSACTIONS

CREATE TABLE balance_transactions (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    amount NUMERIC(10, 2) NOT NULL
        CHECK (amount <> 0),

    type VARCHAR(30) NOT NULL
        CHECK (
            type IN (
                'TOPUP',
                'SESSION_PAYMENT',
                'REFUND',
                'ADJUSTMENT'
            )
        ),

    description TEXT,

    payment_id BIGINT NULL,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT balance_transactions_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT balance_transactions_payment_fk
        FOREIGN KEY (payment_id)
        REFERENCES payments(id)
        ON DELETE SET NULL
);

-- 8. NOTIFICATIONS

CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,

    user_id BIGINT NOT NULL,

    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,

    type VARCHAR(30) NOT NULL DEFAULT 'SYSTEM',

    is_read BOOLEAN NOT NULL DEFAULT FALSE,

    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT notifications_user_fk
        FOREIGN KEY (user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

-- INDEXES

CREATE INDEX idx_bookings_pc_time
    ON bookings (pc_id, start_time, end_time);

CREATE INDEX idx_bookings_user
    ON bookings (user_id);

CREATE INDEX idx_bookings_status
    ON bookings (status);

CREATE INDEX idx_sessions_user
    ON sessions (user_id);

CREATE INDEX idx_sessions_pc
    ON sessions (pc_id);

CREATE INDEX idx_sessions_status
    ON sessions (status);

CREATE INDEX idx_payments_user
    ON payments (user_id);

CREATE INDEX idx_payments_session
    ON payments (session_id);

CREATE INDEX idx_balance_transactions_user
    ON balance_transactions (user_id);

CREATE INDEX idx_notifications_user_read
    ON notifications (user_id, is_read);


-- =========================================================
-- DEFAULT TARIFFS
-- =========================================================

INSERT INTO tariffs (
    name,
    duration_minutes,
    price,
    description
)
VALUES
    ('1 час', 60, 200.00, 'Игровая сессия на 1 час'),
    ('3 часа', 180, 550.00, 'Игровая сессия на 3 часа'),
    ('5 часов', 300, 850.00, 'Игровая сессия на 5 часов'),
    ('Ночной', 480, 700.00, 'Ночная игровая сессия');


-- =========================================================
-- DEFAULT ADMIN
-- =========================================================
