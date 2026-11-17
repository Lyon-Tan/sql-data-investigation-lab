-- SQLite-compatible teaching schema. Amounts use integer cents.
-- Staging tables deliberately allow bad relationships and duplicate business IDs.
-- A production schema would normally enforce appropriate NOT NULL/UNIQUE/FK rules.
CREATE TABLE customers (
    customer_id TEXT PRIMARY KEY,
    customer_name TEXT NOT NULL
);

CREATE TABLE transactions (
    row_id INTEGER PRIMARY KEY,
    transaction_id TEXT,
    customer_id TEXT,
    amount_cents INTEGER,
    status TEXT,
    created_at TEXT
);

CREATE TABLE payments (
    payment_id TEXT PRIMARY KEY,
    transaction_id TEXT,
    amount_cents INTEGER
);
