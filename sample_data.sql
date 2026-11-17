INSERT INTO customers (customer_id, customer_name) VALUES
('C001', 'Alex'), ('C002', 'Blair'), ('C003', 'Casey'), ('C004', 'Devon');

INSERT INTO transactions
(row_id, transaction_id, customer_id, amount_cents, status, created_at) VALUES
(1, 'T001', 'C001', 10000, 'COMPLETED', '2026-11-16T09:00:00'),
(2, 'T002', 'C002', 5000, 'COMPLETED', '2026-11-16T09:05:00'),
(3, 'T002', 'C002', 5000, 'COMPLETED', '2026-11-16T09:05:00'),
(4, 'T003', NULL, 2500, 'PENDING', '2026-11-16T09:10:00'),
(5, 'T004', 'C999', 3000, 'COMPLETED', '2026-11-16T09:15:00'),
(6, 'T005', 'C001', -1000, 'FAILED', '2026-11-16T09:20:00'),
(7, 'T006', 'C001', 2000, 'FAILED', '2026-11-16T09:25:00'),
(8, 'T007', 'C003', NULL, 'PENDING', '2026-11-16T09:30:00'),
(9, 'T008', 'C003', 0, 'COMPLETED', '2026-11-16T09:35:00'),
(10, 'T009', 'C004', 7500, 'COMPLETED', '2026-11-16T09:40:00'),
(11, 'T010', 'C004', 4000, NULL, NULL);

INSERT INTO payments (payment_id, transaction_id, amount_cents) VALUES
('P001', 'T001', 10000),
('P002', 'T002', 5000),
('P003', 'T004', 2800),
('P004', 'T008', 0),
('P005', 'T009', 5000),
('P006', 'T009', 2500),
('P007', 'T999', 900),
('P008', NULL, 100),
('P009', 'T007', NULL);
