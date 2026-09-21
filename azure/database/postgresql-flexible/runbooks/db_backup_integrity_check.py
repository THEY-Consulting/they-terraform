"""Container Apps Job entry point for PostgreSQL backup-integrity checks."""
import datetime
import json
import os
import sys
import time
import urllib.error
import urllib.request

import pg8000.dbapi

API_VERSION = "2022-12-01"
PROVIDER = "Microsoft.DBforPostgreSQL/flexibleServers"


def token():
    endpoint, header = os.environ.get("IDENTITY_ENDPOINT"), os.environ.get("IDENTITY_HEADER")
    if not endpoint or not header:
        raise RuntimeError("Container Apps managed identity endpoint is unavailable")
    request = urllib.request.Request(f"{endpoint}?api-version=2019-08-01&resource=https://management.azure.com/", headers={"X-IDENTITY-HEADER": header})
    with urllib.request.urlopen(request, timeout=30) as response:
        return json.loads(response.read())["access_token"]


def url(cfg, name):
    return f"https://management.azure.com/subscriptions/{cfg['SUBSCRIPTION_ID']}/resourceGroups/{cfg['RESOURCE_GROUP_NAME']}/providers/{PROVIDER}/{name}?api-version={API_VERSION}"


def request(method, endpoint, access_token, body=None):
    payload = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(endpoint, data=payload, method=method, headers={"Authorization": f"Bearer {access_token}", "Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            raw = response.read()
            return json.loads(raw) if raw else {}
    except urllib.error.HTTPError as exc:
        raise RuntimeError(f"Azure API {method} failed with {exc.code}: {exc.read().decode()}") from exc


def restore(access_token, cfg, name, restore_point):
    source = f"/subscriptions/{cfg['SUBSCRIPTION_ID']}/resourceGroups/{cfg['RESOURCE_GROUP_NAME']}/providers/{PROVIDER}/{cfg['SOURCE_SERVER_NAME']}"
    request("PUT", url(cfg, name), access_token, {"location": cfg["LOCATION"], "properties": {"createMode": "PointInTimeRestore", "sourceServerResourceId": source, "pointInTimeUTC": restore_point, "network": {"publicNetworkAccess": "Enabled"}}})


def wait_ready(access_token, cfg, name):
    deadline = time.time() + 3600
    while time.time() < deadline:
        try:
            server = request("GET", url(cfg, name), access_token)
            state = server.get("properties", {}).get("state", "Unknown")
            print(f"Restore server state: {state}")
            if state == "Ready":
                return server
        except RuntimeError as exc:
            if "404" not in str(exc):
                raise
        time.sleep(30)
    raise TimeoutError("Restored server did not become ready within 60 minutes")


def firewall(access_token, cfg, name):
    request("PUT", url(cfg, name).replace(f"/{name}?", f"/{name}/firewallRules/AllowAzureServices?"), access_token, {"properties": {"startIpAddress": "0.0.0.0", "endIpAddress": "0.0.0.0"}})


def delete(access_token, cfg, name):
    try:
        request("DELETE", url(cfg, name), access_token)
    except RuntimeError as exc:
        if "404" not in str(exc):
            raise


def checks(host, cfg):
    connection = pg8000.dbapi.connect(host=host, port=5432, database=cfg["DATABASE_NAME"], user=cfg["DB_USER"], password=cfg["DB_PASSWORD"], ssl_context=True)
    failures = []
    try:
        cursor = connection.cursor()
        for check in json.loads(cfg["SANITY_CHECKS_JSON"]):
            cursor.execute(check["query"])
            row = cursor.fetchone()
            if row is None or len(row) != 1:
                raise RuntimeError(f"Check '{check['label']}' must return one scalar value")
            passed = not check.get("expect_rows", True) or row[0] > 0
            print(f"{'PASS' if passed else 'FAIL'} {check['label']}: {row[0]}")
            if not passed:
                failures.append(check["label"])
        cursor.close()
    finally:
        connection.close()
    if failures:
        raise RuntimeError(f"Sanity checks failed: {', '.join(failures)}")


def main():
    cfg = {key: os.environ[key] for key in ("SOURCE_SERVER_NAME", "RESOURCE_GROUP_NAME", "SUBSCRIPTION_ID", "LOCATION", "DATABASE_NAME", "DB_USER", "DB_PASSWORD", "SANITY_CHECKS_JSON")}
    # Five-field cron has no every-N-weeks expression. Run the job each selected
    # weekday and make non-matching weeks successful no-ops in UTC.
    if os.environ["SCHEDULE_FREQUENCY"] == "Week" and datetime.datetime.now(datetime.UTC).isocalendar().week % int(os.environ["SCHEDULE_INTERVAL"]) != 0:
        print("Backup integrity check skipped for this weekly interval")
        return
    stamp = datetime.datetime.now(datetime.UTC).strftime("%Y%m%d%H%M")
    restored = f"{cfg['SOURCE_SERVER_NAME'][:42]}-bkp-{stamp}"
    print(f"Backup integrity check started for {cfg['SOURCE_SERVER_NAME']}; restore server: {restored}")
    created = False
    try:
        access_token = token()
        restore(access_token, cfg, restored, (datetime.datetime.now(datetime.UTC) - datetime.timedelta(minutes=10)).strftime("%Y-%m-%dT%H:%M:%SZ"))
        created = True
        server = wait_ready(access_token, cfg, restored)
        firewall(access_token, cfg, restored)
        checks(server["properties"]["fullyQualifiedDomainName"], cfg)
        print("Backup integrity check PASSED")
    except Exception as exc:
        print(f"Backup integrity check FAILED for {cfg['SOURCE_SERVER_NAME']}: {exc}", file=sys.stderr)
        raise
    finally:
        if created:
            try:
                delete(token(), cfg, restored)
                print("Restore server deleted")
            except Exception as exc:
                print(f"WARNING: restore-server cleanup failed: {exc}", file=sys.stderr)


if __name__ == "__main__":
    main()
