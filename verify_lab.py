"""Run the SQL lab in memory and verify selected investigation results."""

import sqlite3
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent


def main():
    with sqlite3.connect(":memory:") as connection:
        connection.executescript((PROJECT_DIR / "schema.sql").read_text(encoding="utf-8"))
        connection.executescript((PROJECT_DIR / "sample_data.sql").read_text(encoding="utf-8"))
        results = []
        statements = []
        pending = ""
        for line in (PROJECT_DIR / "investigation_queries.sql").read_text(
                encoding="utf-8").splitlines(keepends=True):
            pending += line
            if sqlite3.complete_statement(pending):
                statements.append(pending)
                pending = ""
        for statement in statements:
            if not statement.strip():
                continue
            cursor = connection.execute(statement)
            rows = cursor.fetchall()
            results.append(rows)
            print(f"Query {len(results)}: {len(rows)} result rows")
        assert len(results) == 15
        assert results[0] == [("T002", 2)]
        assert {row[1] for row in results[1]} == {"T003", "T004"}
        assert {row[1] for row in results[2]} == {"T003", "T005", "T006", "T010"}
        assert results[3] == [("T004", 3000, 2800)]
        assert results[7] == [("C001", 2)]
        reconciliation = {row[0]: row[1:] for row in results[13]}
        assert reconciliation == {
            "T001": (10000, 10000, 0, "MATCH"),
            "T002": (5000, 5000, None, "BLOCKED_DUPLICATE"),
            "T004": (3000, 2800, -200, "MISMATCH"),
            "T008": (0, 0, 0, "MATCH"),
            "T009": (7500, 7500, 0, "MATCH"),
        }
        assert {row[0] for row in results[14]} == {"P007", "P008"}
        # Regression: missing and unknown payments must not be treated as zero.
        connection.execute("DELETE FROM payments WHERE transaction_id = 'T008'")
        rows = connection.execute(statements[13]).fetchall()
        assert next(row for row in rows if row[0] == "T008")[-1] == "MISSING_PAYMENT"
        connection.execute("INSERT INTO payments VALUES ('PTEST', 'T001', NULL)")
        rows = connection.execute(statements[13]).fetchall()
        assert next(row for row in rows if row[0] == "T001")[-1] == "BLOCKED_UNKNOWN_PAYMENT"
        print("All SQL checks passed. No database file was created.")


if __name__ == "__main__":
    main()
