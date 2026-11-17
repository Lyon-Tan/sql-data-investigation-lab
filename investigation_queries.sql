-- 1. Duplicate business IDs: GROUP BY brings equal IDs together;
-- HAVING filters groups with more than one physical row.
SELECT transaction_id, COUNT(*) AS occurrences
FROM transactions
WHERE transaction_id IS NOT NULL
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- 2. Missing customers: LEFT JOIN retains transactions without a match.
-- This finds both NULL customer IDs and non-NULL orphan IDs such as C999.
SELECT t.row_id, t.transaction_id, t.customer_id
FROM transactions t
LEFT JOIN customers c ON c.customer_id = t.customer_id
WHERE c.customer_id IS NULL;

-- 3. Missing payments: NOT EXISTS checks for absence without multiplying rows.
-- Pending/failed transactions may legitimately have no payment; inspect status.
SELECT t.row_id, t.transaction_id, t.status
FROM transactions t
WHERE NOT EXISTS (
    SELECT 1 FROM payments p WHERE p.transaction_id = t.transaction_id
);

-- 4. Amount mismatches: aggregate split payments first to avoid join fan-out.
-- Only unique transaction IDs with known amounts are comparable here.
WITH payment_totals AS (
    SELECT transaction_id, SUM(amount_cents) AS paid_cents,
           COUNT(*) AS payment_count, COUNT(amount_cents) AS known_amount_count
    FROM payments GROUP BY transaction_id
), unique_transactions AS (
    SELECT transaction_id, MAX(amount_cents) AS expected_cents
    FROM transactions
    WHERE transaction_id IS NOT NULL
    GROUP BY transaction_id
    HAVING COUNT(*) = 1 AND COUNT(amount_cents) = 1
)
SELECT t.transaction_id, t.expected_cents, p.paid_cents
FROM unique_transactions t
INNER JOIN payment_totals p ON p.transaction_id = t.transaction_id
WHERE p.payment_count = p.known_amount_count
  AND t.expected_cents <> p.paid_cents;

-- 5. Raw totals by customer: SUM ignores NULL, so expose NULL and row counts.
-- These are staging totals including duplicates and all statuses, not revenue.
SELECT customer_id, COUNT(*) AS row_count,
       COUNT(*) - COUNT(amount_cents) AS missing_amount_count,
       SUM(amount_cents) AS raw_total_cents
FROM transactions GROUP BY customer_id;

-- 6. Classify amounts: CASE evaluates conditions in order, checking NULL first.
-- Zero is allowed in this lab but is listed separately for investigation.
SELECT row_id, transaction_id, amount_cents,
       CASE WHEN amount_cents IS NULL THEN 'MISSING'
            WHEN amount_cents < 0 THEN 'NEGATIVE'
            WHEN amount_cents = 0 THEN 'ZERO_REVIEW'
            ELSE 'POSITIVE' END AS amount_class
FROM transactions;

-- 7. NULL detection uses IS NULL, since equality with NULL is unknown.
-- Inspect all required transaction fields before reconciling totals.
SELECT * FROM transactions
WHERE transaction_id IS NULL OR customer_id IS NULL OR amount_cents IS NULL
   OR status IS NULL OR created_at IS NULL;

-- 8. Repeated failures: filter failed rows before grouping by customer.
-- HAVING identifies customers with at least two failed staging records.
SELECT customer_id, COUNT(*) AS failed_count
FROM transactions WHERE status = 'FAILED' AND customer_id IS NOT NULL
GROUP BY customer_id HAVING COUNT(*) >= 2;

-- 9. INNER JOIN returns only transactions with a known customer.
-- It does not deduplicate business IDs or prove a payment exists.
SELECT t.row_id, t.transaction_id, c.customer_name
FROM transactions t INNER JOIN customers c ON c.customer_id = t.customer_id;

-- 10. LEFT JOIN preserves every customer, including those without transactions.
-- COUNT(t.row_id), unlike COUNT(*), returns zero for an unmatched customer.
SELECT c.customer_id, c.customer_name, COUNT(t.row_id) AS transaction_rows
FROM customers c LEFT JOIN transactions t ON t.customer_id = c.customer_id
GROUP BY c.customer_id, c.customer_name;

-- 11. GROUP BY/HAVING: find business statuses appearing in several rows.
-- WHERE selects rows; HAVING selects aggregate groups.
SELECT status, COUNT(*) AS row_count
FROM transactions GROUP BY status HAVING COUNT(*) > 1;

-- 12. Scalar subquery: compare each amount to the staging average.
-- AVG ignores NULL; duplicates and negative amounts still affect this baseline.
SELECT row_id, transaction_id, amount_cents FROM transactions
WHERE amount_cents > (SELECT AVG(amount_cents) FROM transactions);

-- 13. CTE names an intermediate set, making the investigation easier to read.
-- Join duplicate IDs back to show every physical source row in each group.
WITH duplicate_ids AS (
    SELECT transaction_id FROM transactions
    WHERE transaction_id IS NOT NULL
    GROUP BY transaction_id HAVING COUNT(*) > 1
)
SELECT t.* FROM transactions t
INNER JOIN duplicate_ids d ON d.transaction_id = t.transaction_id;

-- 14. Expected vs actual for completed transactions, aggregated on both sides.
-- Duplicate or unknown amounts are blocked rather than guessed or counted twice.
-- Missing payments remain distinguishable from an explicit zero payment.
WITH expected AS (
    SELECT transaction_id, COUNT(*) AS transaction_rows,
           COUNT(amount_cents) AS known_amounts,
           MAX(amount_cents) AS expected_cents,
           SUM(CASE WHEN status = 'COMPLETED' THEN 1 ELSE 0 END) AS completed_rows
    FROM transactions WHERE transaction_id IS NOT NULL GROUP BY transaction_id
), actual AS (
    SELECT transaction_id, COUNT(*) AS payment_rows,
           COUNT(amount_cents) AS known_amounts, SUM(amount_cents) AS actual_cents
    FROM payments GROUP BY transaction_id
)
SELECT e.transaction_id, e.expected_cents, a.actual_cents,
       CASE WHEN e.transaction_rows = 1 AND e.known_amounts = 1
                  AND e.expected_cents >= 0 AND a.payment_rows = a.known_amounts
            THEN a.actual_cents - e.expected_cents END AS difference_cents,
       CASE WHEN e.transaction_rows > 1 THEN 'BLOCKED_DUPLICATE'
            WHEN e.known_amounts <> 1 THEN 'BLOCKED_UNKNOWN_EXPECTED'
            WHEN e.expected_cents < 0 THEN 'BLOCKED_NEGATIVE_EXPECTED'
            WHEN a.payment_rows IS NULL THEN 'MISSING_PAYMENT'
            WHEN a.known_amounts <> a.payment_rows THEN 'BLOCKED_UNKNOWN_PAYMENT'
            WHEN e.expected_cents = a.actual_cents THEN 'MATCH'
            ELSE 'MISMATCH' END AS reconciliation_status
FROM expected e LEFT JOIN actual a ON a.transaction_id = e.transaction_id
WHERE e.completed_rows > 0;

-- 15. Reverse reconciliation: payments without a transaction are also defects.
-- NOT EXISTS includes NULL payment transaction IDs, which cannot join by equality.
SELECT p.* FROM payments p
WHERE NOT EXISTS (
    SELECT 1 FROM transactions t WHERE t.transaction_id = p.transaction_id
);
