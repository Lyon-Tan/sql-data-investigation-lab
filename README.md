# SQL Data Investigation Lab

## Overview

This simulated enterprise data troubleshooting lab uses a synthetic staging database to investigate transaction inconsistencies. It deliberately permits duplicate business IDs, missing customers, missing payments, and inconsistent amounts. This is a beginner-to-intermediate learning project, not a production schema, an SAP integration, or a claim of professional support experience.

The SQL foundation of the Technical Interview Foundation Portfolio: reusable practice in relational investigation and data reconciliation.

## Language Notes

This repository uses English as the primary technical language.

Short Traditional Chinese and conversational Malaysian Malay notes are included to support learning and interview revision.

Technical terms are intentionally kept in English where commonly used in the industry.

Traditional Chinese:
繁中備註主要用來快速理解和複習技術概念，部分常用技術詞會保留英文。

Bahasa Melayu:
Nota BM guna gaya yang biasa ditutur di Malaysia supaya lebih senang faham dan explain masa interview. Istilah technical yang biasa digunakan akan kekal dalam English.

See [SQL Learning Notes](LEARNING_NOTES.md) for concise revision of filtering, JOINs, aggregation, NULLs, and reconciliation.

## Why This Project Exists

Develop the habit of checking keys, missing relationships, NULL values, and join cardinality before trusting aggregate results. The numbered investigations make it possible to explain both the query and the reason for running it.

## Business / Technical Scenario

A synthetic transaction export and payment ledger disagree. Investigate whether the discrepancy comes from missing records, repeated business IDs, split payments, or amount mismatches before proposing a correction.

## Skills Demonstrated

- SELECT/WHERE, JOINs, CASE, NULL handling, grouping, and aggregation.
- Duplicate and missing-record investigation.
- Subqueries, CTEs, and expected-versus-actual reconciliation.
- Reasoning about business grain, join fan-out, status scope, and evidence.

## Architecture / Data Flow

```text
schema.sql + sample_data.sql
  -> SQLite learning database
  -> investigation_queries.sql
  -> result sets for comparison and investigation
```

[verify_lab.py](verify_lab.py) offers a separate in-memory verification path. There is no application server or production database connection.

## Dataset / Data Model

`customers.customer_id` identifies a customer. `transactions.row_id` identifies a physical staging row; `transaction_id` is a business identifier that is intentionally not unique. A transaction may have multiple payment records, representing split payments. Table constraints are deliberately relaxed for staging investigations; production constraints should be designed around actual business rules.

The sample contains 4 customers, 11 physical transaction rows, and 9 payment rows. Amounts are integer cents; transactions do not carry a currency field. See [schema.sql](schema.sql) and [sample_data.sql](sample_data.sql).

## How It Works

The numbered query file covers duplicates, missing customer relationships, missing payments, amount mismatches, customer totals, CASE, NULL, repeated failures, INNER JOIN, LEFT JOIN, GROUP BY/HAVING, a subquery, a CTE, completed-transaction reconciliation, and orphan payments. Each query explains its purpose and mechanism.

An INNER JOIN returns matching relationships. A LEFT JOIN preserves every row on the left and supplies NULLs when the right side has no match. A right-table filter in WHERE can unintentionally remove unmatched rows. Use `IS NULL`, not `= NULL`. `SUM` and `AVG` ignore NULL values; missing amounts must not silently become known zero values.

Reconciliation compares expected values with independently recorded actual values at a clearly defined grain and scope. This lab reconciles completed transactions by transaction ID. Failed/pending records may not require a payment. Check orphan payments separately so a transaction-led report does not hide them.

> 繁中備註：先確認 JOIN 的資料關係與彙總粒度，再比較金額；NULL 和缺少付款不能直接當成零。
>
> ENG: Check join cardinality and aggregation grain before comparing amounts; missing payments and NULL are not known zero values.
>
> BM: Check hubungan JOIN dan tahap aggregate dulu sebelum banding amount. Payment missing atau NULL bukan bermaksud sifar.

## How to Run

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

> 繁中備註：使用新的 SQLite database，依序載入 schema、sample data 和 investigation queries；也可用 `python verify_lab.py` 做記憶體內驗證。
>
> ENG: Load schema, sample data, and investigation queries into a fresh SQLite database in that order, or use `python verify_lab.py` for an in-memory check.
>
> BM: Guna SQLite database baru dan load schema, sample data, kemudian investigation queries ikut urutan. Boleh juga run `python verify_lab.py` untuk check dalam memory.

## Example Investigation

Start with `T004`: the expected amount is 3,000 cents and the recorded payment is 2,800 cents. Query 4 exposes the mismatch; query 14 reports a difference of -200 cents. Contrast `T009`, whose two payments correctly total 7,500 cents. This explains why summing raw joined rows or comparing each split payment individually can mislead an investigation.

> 繁中備註：`T004` 少了 200 cents；`T009` 的兩筆付款加起來則正確，說明比較前要先加總 split payments。
>
> ENG: T004 is short by 200 cents, while T009 reconciles after its split payments are summed.
>
> BM: T004 kurang 200 cents. T009 pula match bila dua payment dijumlahkan, jadi aggregate split payment dulu sebelum banding.

## Expected Results

- Query 1: `T002` appears twice.
- Query 2: `T003` has a NULL customer and `T004` references nonexistent `C999`.
- Query 3: `T003`, `T005`, `T006`, and `T010` have no payment record. Status determines whether this is an incident.
- Query 4: `T004` expects 3,000 cents but received 2,800.
- Query 8: `C001` has two failed records.
- Query 14: `T001`, `T008`, and `T009` match; `T002` is blocked as a duplicate; `T004` is a mismatch with a difference of -200 cents.
- Query 15: `P007` references nonexistent `T999`; `P008` has no transaction ID.

`T009` has two payments totaling 7,500 cents. Joining raw payment rows and transaction rows before summing can inflate totals. Aggregate each side at the intended business grain first. Duplicate transactions require investigation rather than an arbitrary choice of one record. Query 14 exposes one candidate expected amount for a duplicate group, but its blocked status makes clear that the value is not approved for reconciliation.

> 繁中備註：預期找到重複 ID、缺少的關聯和金額差異；`BLOCKED_DUPLICATE` 表示需先調查，不能當成已完成對帳。
>
> ENG: Expect duplicate IDs, missing relationships, and amount mismatches; a blocked duplicate is not a completed reconciliation.
>
> BM: Jangka jumpa ID duplicate, hubungan missing dan amount tak sama. Kalau status blocked duplicate, kena siasat dulu; belum boleh kata reconciliation selesai.

## Troubleshooting / Root Cause Analysis

Confirm the scope, reproduce the mismatch, isolate duplicate or missing relationships, validate the explanation with source records, propose an approved fix, and prevent recurrence.

During a production incident, confirm the scope and time window, use approved read-only access, reproduce the discrepancy, inspect joins and aggregates, correlate logs, validate the cause, and seek approval for a correction. Run targeted queries with appropriate indexes and review execution plans before large scans. These queries demonstrate investigation only; they do not update data.

> 繁中備註：先確認比較範圍、重複資料、分次付款和時間差；查詢只用來調查，不會更新資料。
>
> ENG: Check scope, duplicates, split payments, and timing; these investigation queries do not update data.
>
> BM: Semak skop, duplicate, split payment dan timing dulu. Query ni untuk siasat sahaja, bukan update data.

## Limitations

- This is deliberately permissive staging data, not a production integrity design.
- No currency conversion, settlement window, timezone logic, or automated remediation is implemented.
- Raw totals include staging duplicates and all statuses; they are not approved revenue figures.
- Known zero amounts, missing payments, and NULL amounts have different meanings.
- SQLite execution does not prove portability or performance on another database engine.
- Query optimisation, index effectiveness, and production-scale execution plans have not been benchmarked.

## Interview Talking Points

Explain the intended grain before each JOIN or SUM. Show why duplicates can inflate totals, why NULL is not zero, and why expected-versus-actual scope matters.

### Interview questions and answers

**WHERE versus HAVING?** WHERE filters individual rows before grouping. HAVING filters the resulting groups.

**Why a separate row ID?** It allows duplicate business IDs to be examined as separate source records.

**Why NOT EXISTS?** It expresses a missing relationship directly and avoids multiplying the outer records.

**What is a CTE?** A named query result within one statement that improves readability; it is not automatically a performance improvement.

**Why not use floating-point amounts?** Integer cents represent this lab's fixed two-decimal currency amounts exactly. Real multi-currency systems require explicit precision and currency rules.

**How would you investigate a mismatch?** Verify scope, duplicates, partial payments, status, currency, and timing before comparing totals and checking logs.

> 繁中備註：mismatch 不一定是付款錯誤，也可能是 JOIN 放大筆數、分次付款或時間差；先檢查比較範圍。
>
> 🇲🇾 BM: Mismatch tak semestinya payment salah. Mungkin JOIN gandakan row, ada split payment atau timing berbeza. Semak skop perbandingan dulu.

## Quick Interview Revision

### Why LEFT JOIN for troubleshooting?

English: Preserve every left-side record, then check a right-side key for NULL to identify missing matches.

> 繁中備註：保留左邊全部資料，再用右邊 key 的 NULL 找出缺少的 matching record。
>
> 🇲🇾 BM: Kekalkan semua rekod kiri, kemudian check key kanan yang NULL untuk cari rekod yang tak match.

### WHERE versus HAVING

English: WHERE filters rows before grouping; HAVING filters aggregate groups.

> 繁中備註：`WHERE` 先篩選每筆資料，`HAVING` 再篩選分組後的結果。
>
> 🇲🇾 BM: `WHERE` tapis row sebelum grouping; `HAVING` tapis hasil selepas aggregate.

### How do you reconcile transactions?

English: Aggregate payments at the transaction level before comparing expected and actual amounts; investigate duplicates and unknown values first.

> 繁中備註：先按 transaction 加總付款，再比較 expected 和 actual；重複和未知金額要先調查。
>
> 🇲🇾 BM: Jumlahkan payment ikut transaction dulu, baru banding expected dengan actual. Siasat duplicate dan amount yang tak diketahui dahulu.

## Role Relevance

The relevance below is about query reasoning in simulated exercises, not professional system access, ERP expertise, or financial crime operations.

| Relevant area | Transferable practice demonstrated |
| --- | --- |
| Application Support | Find missing relationships and explain mismatches during an investigation. |
| Data Analyst | Check completeness and aggregation assumptions before interpreting totals. |
| Business Systems | Translate expected transaction behaviour into explicit reconciliation rules. |
| ERP Support | Practise investigating exported transaction/master-data relationships; no ERP integration exists. |
| Risk Analytics | Assess the quality of inputs used for risk analysis; no risk model is implemented. |
| Fraud Investigation | Investigate transaction inconsistencies as leads, not proof of fraud. |
| Financial Crime Technology | Practise traceable data investigation; no AML detection or compliance workflow is implemented. |

## Future Improvements

Planned possibilities only; none of the following is implemented:

- Window functions for ranking and repeat-event investigations.
- Query optimisation based on measured workloads.
- Execution-plan comparisons before and after adding suitable indexes.
- Larger reconciliation scenarios with explicit time and currency scope.
- Transaction monitoring examples with clearly documented synthetic rules.

Keep new scenarios independently checkable and distinguish a monitoring alert from a confirmed incident.

## Learning Notes

[LEARNING_NOTES.md](LEARNING_NOTES.md) provides concise English, Traditional Chinese, and conversational Malaysian Malay revision. Focus on LEFT JOIN, GROUP BY/HAVING, NULL, and reconciliation before memorizing query syntax.
