# SQL Data Investigation Lab

This simulated enterprise data troubleshooting lab uses a synthetic staging database to investigate transaction inconsistencies. It deliberately permits duplicate business IDs, missing customers, missing payments, and inconsistent amounts. This is a beginner-to-intermediate learning project, not a production schema, an SAP integration, or a claim of professional support experience.

## Run

Use a fresh SQLite database. From this project folder, open the SQLite CLI and enter:

```sql
.open lab.db
.read schema.sql
.read sample_data.sql
.headers on
.mode column
.read investigation_queries.sql
```

Alternatively, paste the three SQL files in that order into a SQLite SQL editor, without the CLI dot commands. Python's standard-library `sqlite3` also works if the CLI is unavailable. Load schema/data only once per fresh database; reloading causes existing-table or key errors. The SQL uses common constructs, but other database engines may need datatype adjustments. Amounts are integer cents; timestamps are text for a simple lab. No real credentials or customer data are required.

For an automated local check without installing SQLite CLI, run `python verify_lab.py`. It executes all 15 queries in memory, checks known findings and two reconciliation edge cases, and creates no database file. Run normally without Python's `-O` option so its assertions remain enabled.

## Data model and investigation

`customers.customer_id` identifies a customer. `transactions.row_id` identifies a physical staging row; `transaction_id` is a business identifier that is intentionally not unique. A transaction may have multiple payment records, representing split payments. Table constraints are deliberately relaxed for staging investigations; production constraints should be designed around actual business rules.

The numbered query file covers duplicates, missing customer relationships, missing payments, amount mismatches, customer totals, CASE, NULL, repeated failures, INNER JOIN, LEFT JOIN, GROUP BY/HAVING, a subquery, a CTE, completed-transaction reconciliation, and orphan payments. Each query explains its purpose and mechanism.

## Expected observations

- Query 1: `T002` appears twice.
- Query 2: `T003` has a NULL customer and `T004` references nonexistent `C999`.
- Query 3: `T003`, `T005`, `T006`, and `T010` have no payment record. Status determines whether this is an incident.
- Query 4: `T004` expects 3,000 cents but received 2,800.
- Query 8: `C001` has two failed records.
- Query 14: `T001`, `T008`, and `T009` match; `T002` is blocked as a duplicate; `T004` is a mismatch with a difference of -200 cents.
- Query 15: `P007` references nonexistent `T999`; `P008` has no transaction ID.

`T009` has two payments totaling 7,500 cents. Joining raw payment rows and transaction rows before summing can inflate totals. Aggregate each side at the intended business grain first. Duplicate transactions require investigation rather than an arbitrary choice of one record. Query 14 exposes one candidate expected amount for a duplicate group, but its blocked status makes clear that the value is not approved for reconciliation.

## Troubleshooting concepts

An INNER JOIN returns matching relationships. A LEFT JOIN preserves every row on the left and supplies NULLs when the right side has no match. A right-table filter in WHERE can unintentionally remove unmatched rows. Use `IS NULL`, not `= NULL`. `SUM` and `AVG` ignore NULL values; missing amounts must not silently become known zero values.

Reconciliation compares expected values with independently recorded actual values at a clearly defined grain and scope. This lab reconciles completed transactions by transaction ID. Failed/pending records may not require a payment. Check orphan payments separately so a transaction-led report does not hide them.

During a production incident, confirm the scope and time window, use approved read-only access, reproduce the discrepancy, inspect joins and aggregates, correlate logs, validate the cause, and seek approval for a correction. Run targeted queries with appropriate indexes and review execution plans before large scans. These queries demonstrate investigation only; they do not update data.

## Interview questions and answers

**WHERE versus HAVING?** WHERE filters individual rows before grouping. HAVING filters the resulting groups.

**Why a separate row ID?** It allows duplicate business IDs to be examined as separate source records.

**Why NOT EXISTS?** It expresses a missing relationship directly and avoids multiplying the outer records.

**What is a CTE?** A named query result within one statement that improves readability; it is not automatically a performance improvement.

**Why not use floating-point amounts?** Integer cents represent this lab's fixed two-decimal currency amounts exactly. Real multi-currency systems require explicit precision and currency rules.

**How would you investigate a mismatch?** Verify scope, duplicates, partial payments, status, currency, and timing before comparing totals and checking logs.
