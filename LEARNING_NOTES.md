# SQL Learning Notes

Concise revision for the simulated data investigation lab. Read alongside the unchanged SQL and the [README](README.md).

## SELECT and WHERE

`SELECT` chooses output columns or expressions. `WHERE` filters individual rows before aggregation, such as selecting only failed transactions.

> 🇹🇼 繁中備註：`SELECT` 決定要看哪些欄位；`WHERE` 先篩選符合條件的資料，再進行彙總。
>
> 🇲🇾 BM: `SELECT` pilih column yang nak tengok. `WHERE` tapis row dulu, contohnya ambil transaction yang failed sahaja.

## INNER JOIN

`INNER JOIN` returns matching combinations from both sides. A one-to-many match can produce several output rows for one transaction.

> 🇹🇼 繁中備註：`INNER JOIN` 只保留兩邊有 matching record 的組合。一對多的關係可能讓同一筆 transaction 出現多列。
>
> 🇲🇾 BM: `INNER JOIN` ambil rekod yang match pada kedua-dua table. Kalau satu transaction ada banyak payment, output boleh ada beberapa row untuk transaction yang sama.

## LEFT JOIN and missing records

`LEFT JOIN` preserves every left-side row. Test a non-nullable right-side key with `IS NULL` to find unmatched records. A right-side filter in `WHERE` can accidentally remove those missing matches.

> 🇹🇼 繁中備註：`LEFT JOIN` 保留左邊全部資料；右邊沒有 match 時會得到 NULL，很適合找 missing records。右邊欄位的 `WHERE` 條件可能不小心把這些資料篩掉。
>
> 🇲🇾 BM: `LEFT JOIN` kekalkan semua rekod table kiri. Kalau kanan tak ada match, key kanan jadi NULL. Senang cari data missing, tapi hati-hati sebab filter `WHERE` pada table kanan boleh buang row tu.

## GROUP BY and HAVING

`GROUP BY` forms groups, such as rows with the same transaction ID. `HAVING` filters aggregate groups, for example `COUNT(*) > 1` to detect repeated IDs.

> 🇹🇼 繁中備註：`GROUP BY` 把相同 ID 分成一組；`HAVING` 篩選彙總後的結果。`COUNT(*) > 1` 可以找出重複 ID。
>
> 🇲🇾 BM: `GROUP BY` kumpulkan row ikut ID. `HAVING` tapis hasil selepas aggregate, macam cari ID yang muncul lebih daripada sekali.

## COUNT and SUM

`COUNT(*)` counts rows, while `COUNT(column)` counts non-NULL values. `SUM` adds known numeric values and ignores NULL; no known values produces NULL, not a confirmed zero. Check missing-value counts before trusting totals.

> 🇹🇼 繁中備註：`COUNT(*)` 算列數，`COUNT(column)` 不算 NULL。`SUM` 會忽略 NULL；沒有已知金額時不能當成已確認的零。
>
> 🇲🇾 BM: `COUNT(*)` kira semua row, tapi `COUNT(column)` tak kira NULL. `SUM` jumlahkan value yang ada; kalau semua amount tak diketahui, jangan anggap jumlah tu sifar.

## CASE WHEN and NULL

`CASE WHEN` classifies records using explicit conditions, such as missing, negative, or zero amounts. `NULL` means missing or unknown; test with `IS NULL`, not `= NULL`.

> 🇹🇼 繁中備註：`CASE WHEN` 可以分類金額問題。NULL 表示缺失或未知，不等於零；要用 `IS NULL` 檢查。
>
> 🇲🇾 BM: `CASE WHEN` bantu kategorikan amount, contohnya missing atau negatif. NULL maksudnya tak ada value atau belum diketahui, bukan sifar. Guna `IS NULL` untuk check.

## DISTINCT and duplicate detection

`DISTINCT` removes duplicate combinations from a query result. It does not correct source data or explain why duplicates exist. Use `GROUP BY ... HAVING COUNT(*) > 1` to expose duplicate business IDs for investigation.

> 🇹🇼 繁中備註：`DISTINCT` 只讓查詢結果不重複，不會修正來源資料。調查重複 ID 時，要看每組筆數和原始資料。
>
> 🇲🇾 BM: `DISTINCT` buang hasil berulang dalam output sahaja, bukan fix data asal. Untuk siasat duplicate ID, tengok count setiap group dan semak rekod asal.

## Subquery and CTE

A subquery nests a query inside another statement. A CTE names an intermediate query with `WITH`, making multi-step reasoning easier to read; it is not automatically faster.

> 🇹🇼 繁中備註：subquery 是查詢裡面的另一個查詢；CTE 用 `WITH` 幫中間結果命名，讓步驟更清楚，但不保證更快。
>
> 🇲🇾 BM: Subquery ialah query dalam query lain. CTE guna `WITH` untuk bagi nama pada hasil sementara supaya senang baca, tapi tak semestinya lebih laju.

## Expected vs actual transaction reconciliation

Compare expected transaction amounts with actual payment totals at the same transaction grain, currency, status scope, and time window. Aggregate split payments first. Block ambiguous duplicate transactions and unknown amounts rather than guessing a match.

> 🇹🇼 繁中備註：reconciliation 要在相同 transaction、幣別、狀態範圍和時間範圍比較 expected 與 actual。先加總分次付款；重複交易或未知金額要先釐清，不能猜結果。
>
> 🇲🇾 BM: Masa reconciliation, banding expected dengan actual untuk transaction, currency, skop status dan tempoh yang sama. Jumlahkan split payment dulu. Kalau transaction duplicate atau amount tak diketahui, siasat dulu sebelum kata match.

## Data mismatch investigation

A mismatch is a symptom. Check missing records, join cardinality, duplicates, partial payments, status, and timing before proposing a cause or correction.

> 🇹🇼 繁中備註：金額不一致只是現象。先查缺失資料、JOIN 筆數、重複、分次付款和時間差，再確認原因。
>
> 🇲🇾 BM: Amount tak sama tu simptom. Semak data missing, bilangan row lepas JOIN, duplicate, partial payment dan timing dulu sebelum tentukan punca.
