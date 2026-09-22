# Backup-integrity image

Consumer deployment pipelines build and publish this image to their own private Azure Container Registry. Build from the `runbooks` directory:

```sh
docker build -f backup-integrity/Dockerfile -t <registry>/postgresql-backup-integrity:<version> .
```

## Local integration test

From the `runbooks/backup-integrity` directory, run:

```sh
docker compose -f docker-compose.local-test.yml up --build --abort-on-container-exit --exit-code-from checks
docker compose -f docker-compose.local-test.yml down --volumes
```

This runs the image against an ephemeral PostgreSQL 16 container, verifies a passing scalar check, and verifies that an empty-result check fails. TLS is disabled only for this local test; the production job defaults to TLS.

Publish an immutable version tag or digest; Terraform rejects `:latest`. The consumer pipeline must build, vulnerability-scan, generate an SBOM, and push the image before applying Terraform. The Dockerfile follows the maintained `python:3.13-alpine` stream and applies available Alpine security updates at build time. Rebuild at least monthly and immediately for critical Python/Alpine advisories; the Trivy High/Critical scan must pass without suppressions or severity downgrades before publishing.

When checks are enabled, the consumer passes the image reference and its ACR ID/login server to the module. The module creates a dedicated user-assigned identity with only `AcrPull` for image retrieval. The job's system-assigned identity retains the PostgreSQL and Key Vault permissions; no registry credentials are stored in Terraform, Key Vault, or the job.

The module performs a direct cutover: applying it removes the Automation resources and creates the job. Manually start one execution immediately after deployment, then confirm `Backup integrity check PASSED` in Log Analytics and that the temporary server was deleted.

## Datadog tracking

If the environment already exports Azure Container Apps logs to Datadog, create a log monitor matching `Backup integrity check FAILED` for failure and a freshness monitor matching `Backup integrity check PASSED` for the selected schedule. The log lines include the source server name and never include the database password. The module also creates an Azure Monitor failed-check alert by default; existing action groups can be attached with `backup_integrity_alert_action_group_ids`.
