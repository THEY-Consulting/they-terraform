"""Integration test for the checker against the local Docker PostgreSQL service."""

import json
import os

from db_backup_integrity_check import checks


CONFIG = {
    "DATABASE_NAME": "postgres",
    "DB_USER": "postgres",
    "DB_PASSWORD": "local-test-password",
}


def run(checks_to_run):
    config = CONFIG | {"SANITY_CHECKS_JSON": json.dumps(checks_to_run)}
    checks("postgres", config)


def main():
    os.environ["DB_SSL"] = "false"

    run([{
        "label": "postgres_is_reachable",
        "query": "SELECT 1",
        "expect_rows": True,
    }])

    try:
        run([{
            "label": "empty_result_fails",
            "query": "SELECT COUNT(*) FROM pg_catalog.pg_tables WHERE false",
            "expect_rows": True,
        }])
    except RuntimeError as exc:
        if "empty_result_fails" not in str(exc):
            raise
        print("Expected failed integrity check was reported")
    else:
        raise AssertionError("An empty result must fail an expect_rows integrity check")


if __name__ == "__main__":
    main()
