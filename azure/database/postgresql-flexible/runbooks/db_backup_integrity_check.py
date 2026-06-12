"""
Azure Automation Runbook: DB Backup Integrity Check

Validates PostgreSQL backup integrity by:
  1. Triggering a point-in-time restore to a temporary server
  2. Running configurable sanity checks against the restored database
  3. Deleting the temporary server (always, even on failure)

Configuration is baked in by Terraform templatefile() at plan time.
"""

import subprocess
import sys

# Install pg8000 at runtime so pip resolves the full dependency tree automatically.
# This avoids manually tracking transitive deps (scramp, asn1crypto, dateutil, etc.)
# as pre-loaded wheel resources in Terraform.
subprocess.check_call(
    [sys.executable, "-m", "pip", "install", "--quiet", "pg8000"],
    stdout=subprocess.DEVNULL,
)

import datetime
import json
import os
import time
import urllib.error
import urllib.request

POSTGRES_API_VERSION = "2022-12-01"
POSTGRES_PROVIDER = "Microsoft.DBforPostgreSQL/flexibleServers"


# ---------------------------------------------------------------------------
# Azure Managed Identity helpers
# ---------------------------------------------------------------------------

def get_access_token(resource: str = "https://management.azure.com/") -> str:
    """Obtain a bearer token via the Automation Account Managed Identity endpoint."""
    endpoint = os.environ.get("IDENTITY_ENDPOINT")
    header = os.environ.get("IDENTITY_HEADER")
    if not endpoint or not header:
        raise RuntimeError(
            "IDENTITY_ENDPOINT / IDENTITY_HEADER not set. "
            "Ensure System Assigned Managed Identity is enabled on the Automation Account."
        )
    url = f"{endpoint}?api-version=2019-08-01&resource={resource}"
    req = urllib.request.Request(url, headers={"X-IDENTITY-HEADER": header})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read())["access_token"]


def azure_request(method: str, url: str, token: str, body: dict = None) -> dict:
    """Make a single Azure REST API call and return the parsed JSON response."""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    data = json.dumps(body).encode() if body else None
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"Azure API {method} {url} → {exc.code}: {exc.read().decode()}") from exc


# ---------------------------------------------------------------------------
# PostgreSQL Flexible Server helpers
# ---------------------------------------------------------------------------

def server_url(subscription_id: str, resource_group: str, server_name: str) -> str:
    base = "https://management.azure.com"
    return (
        f"{base}/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        f"/providers/{POSTGRES_PROVIDER}/{server_name}"
        f"?api-version={POSTGRES_API_VERSION}"
    )


def trigger_pitr(token, subscription_id, resource_group, source_server, restore_server, location, restore_point_utc):
    """Start a point-in-time restore. Returns immediately (async operation).

    Public network access is explicitly enabled on the restore server so the
    Automation sandbox (which runs outside any VNet) can connect to it.
    """
    source_id = (
        f"/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        f"/providers/{POSTGRES_PROVIDER}/{source_server}"
    )
    body = {
        "location": location,
        "properties": {
            "createMode": "PointInTimeRestore",
            "sourceServerResourceId": source_id,
            "pointInTimeUTC": restore_point_utc,
        },
    }
    print(f"  Restore point: {restore_point_utc}")
    azure_request("PUT", server_url(subscription_id, resource_group, restore_server), token, body)


def add_firewall_rule(token, subscription_id, resource_group, server_name, rule_name, start_ip, end_ip):
    """Add a firewall rule to the server. Using 0.0.0.0-0.0.0.0 allows all Azure services."""
    base = "https://management.azure.com"
    url = (
        f"{base}/subscriptions/{subscription_id}/resourceGroups/{resource_group}"
        f"/providers/{POSTGRES_PROVIDER}/{server_name}/firewallRules/{rule_name}"
        f"?api-version={POSTGRES_API_VERSION}"
    )
    body = {"properties": {"startIpAddress": start_ip, "endIpAddress": end_ip}}
    azure_request("PUT", url, token, body)


def wait_for_ready(token, subscription_id, resource_group, server_name, timeout_minutes=60):
    """Poll until server state == 'Ready'. Returns the server JSON.

    404 responses are treated as transient (server not yet visible in ARM
    during the first minutes of provisioning) and retried until the deadline.
    """
    deadline = time.time() + timeout_minutes * 60
    while time.time() < deadline:
        try:
            server = azure_request(
                "GET",
                server_url(subscription_id, resource_group, server_name),
                token,
            )
        except RuntimeError as exc:
            if "→ 404:" in str(exc):
                print("  Server not yet visible in ARM, retrying...")
                time.sleep(30)
                continue
            raise
        state = server.get("properties", {}).get("state", "Unknown")
        print(f"  Server state: {state}")
        if state == "Ready":
            return server
        time.sleep(30)
    raise TimeoutError(f"Server '{server_name}' did not become Ready within {timeout_minutes} min")


def delete_server(token, subscription_id, resource_group, server_name):
    """Issue DELETE on the server; ignore 404 (already gone)."""
    url = server_url(subscription_id, resource_group, server_name)
    headers = {"Authorization": f"Bearer {token}", "Content-Length": "0"}
    req = urllib.request.Request(url, headers=headers, method="DELETE")
    try:
        urllib.request.urlopen(req, timeout=30)
    except urllib.error.HTTPError as exc:
        if exc.code != 404:
            raise


# ---------------------------------------------------------------------------
# Sanity checks — rendered by Terraform templatefile() at plan time
# ---------------------------------------------------------------------------

SANITY_CHECKS = [
%{ for check in sanity_checks ~}
    ("${check.label}", """${check.query}""", ${check.expect_rows ? "True" : "False"}),
%{ endfor ~}
]


def run_sanity_checks(host: str, db_name: str, db_user: str, db_password: str):
    import pg8000.dbapi  # noqa: PLC0415 — pure Python driver; installed as Automation package

    conn = pg8000.dbapi.connect(
        host=host, port=5432, database=db_name,
        user=db_user, password=db_password,
        ssl_context=True,  # use SSL, required by Azure PostgreSQL Flexible Server
    )
    cur = conn.cursor()
    failures = []
    try:
        for label, query, expect_rows in SANITY_CHECKS:
            cur.execute(query)
            count = cur.fetchone()[0]
            ok = count > 0 if expect_rows else True
            status = "✓" if ok else "✗"
            print(f"  {status} {label}: {count} rows")
            if not ok:
                failures.append(f"{label} is empty")
    finally:
        cur.close()
        conn.close()

    if failures:
        raise RuntimeError(f"Sanity checks failed: {', '.join(failures)}")
    print("All sanity checks passed.")


# ---------------------------------------------------------------------------
# Configuration — values baked in by Terraform templatefile() at plan time
# ---------------------------------------------------------------------------

SOURCE_SERVER_NAME  = "${source_server_name}"
RESOURCE_GROUP_NAME = "${resource_group_name}"
SUBSCRIPTION_ID     = "${subscription_id}"
LOCATION            = "${location}"
DATABASE_NAME       = "${database_name}"
DB_USER             = "${db_user}"
DB_PASSWORD         = "${db_password}"


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main():
    timestamp = datetime.datetime.utcnow().strftime("%Y%m%d%H%M")
    # Max server name length is 63; keep prefix to 42 chars to accommodate suffix
    restore_server = f"{SOURCE_SERVER_NAME[:42]}-bkp-{timestamp}"
    restore_point = (
        datetime.datetime.utcnow() - datetime.timedelta(minutes=10)
    ).strftime("%Y-%m-%dT%H:%M:%SZ")

    print(f"=== DB Backup Integrity Check ===")
    print(f"Source server : {SOURCE_SERVER_NAME}")
    print(f"Restore server: {restore_server}")

    token = get_access_token()
    restore_created = False

    try:
        print("\n[1/3] Triggering point-in-time restore...")
        trigger_pitr(
            token,
            SUBSCRIPTION_ID,
            RESOURCE_GROUP_NAME,
            SOURCE_SERVER_NAME,
            restore_server,
            LOCATION,
            restore_point,
        )
        restore_created = True

        print("\n[2/3] Waiting for restored server to become ready...")
        server = wait_for_ready(
            token, SUBSCRIPTION_ID, RESOURCE_GROUP_NAME, restore_server
        )
        fqdn = server["properties"]["fullyQualifiedDomainName"]
        print(f"  Server ready: {fqdn}")

        print("  Adding firewall rule for Azure services...")
        add_firewall_rule(
            token, SUBSCRIPTION_ID, RESOURCE_GROUP_NAME, restore_server,
            "AllowAzureServices", "0.0.0.0", "0.0.0.0",
        )

        print("\n[3/3] Running sanity checks...")
        run_sanity_checks(fqdn, DATABASE_NAME, DB_USER, DB_PASSWORD)

        print("\n✓ Backup integrity check PASSED")

    except Exception as exc:
        print(f"\n✗ Backup integrity check FAILED: {exc}", file=sys.stderr)
        raise

    finally:
        if restore_created:
            print(f"\n[cleanup] Deleting restore server '{restore_server}'...")
            try:
                token = get_access_token()  # refresh — restore can take ~45 min
                delete_server(token, SUBSCRIPTION_ID, RESOURCE_GROUP_NAME, restore_server)
                print("  Restore server deleted.")
            except Exception as exc:
                print(f"  WARNING: Failed to delete restore server: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
