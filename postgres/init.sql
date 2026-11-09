CREATE TABLE accounts (
    id       SERIAL PRIMARY KEY,
    owner    TEXT NOT NULL,
    balance  NUMERIC(14, 2) NOT NULL CHECK (balance >= 0),
    currency CHAR(3) NOT NULL
);

CREATE TABLE payments (
    id           BIGSERIAL PRIMARY KEY,
    from_account INTEGER NOT NULL REFERENCES accounts (id),
    to_account   INTEGER NOT NULL REFERENCES accounts (id),
    amount       NUMERIC(14, 2) NOT NULL CHECK (amount > 0),
    currency     CHAR(3) NOT NULL,
    status       TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending', 'completed', 'rejected')),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    processed_at TIMESTAMPTZ
);

INSERT INTO accounts (owner, balance, currency) VALUES
    ('Test Account 01', 10000.00, 'USD'),
    ('Test Account 02',  8000.00, 'USD'),
    ('Test Account 03',  6000.00, 'USD'),
    ('Test Account 04',  5000.00, 'USD'),
    ('Test Account 05',  4000.00, 'USD'),
    ('Test Account 06',  3000.00, 'USD'),
    ('Test Account 07',  2000.00, 'USD'),
    ('Test Account 08',  1000.00, 'USD'),
    ('Test Account 09',   500.00, 'USD'),
    ('Test Account 10',   100.00, 'USD');
