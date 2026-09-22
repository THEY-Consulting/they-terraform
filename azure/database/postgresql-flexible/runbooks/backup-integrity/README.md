# Backup-integrity image

Build from the `runbooks` directory:

```sh
docker build -f backup-integrity/Dockerfile -t ghcr.io/they-consulting/they-terraform-postgresql-backup-integrity:postgresql-backup-integrity-v1.0.0 .
```

## Local integration test

From the `runbooks/backup-integrity` directory, run:

```sh
docker compose -f docker-compose.local-test.yml up --build --abort-on-container-exit --exit-code-from checks
docker compose -f docker-compose.local-test.yml down --volumes
```

This runs the image against an ephemeral PostgreSQL 16 container, verifies a passing scalar check, and verifies that an empty-result check fails. TLS is disabled only for this local test; the production job defaults to TLS.

Publish immutable `postgresql-backup-integrity-v<semver>` tags only; Terraform rejects `:latest`. The GitHub Actions workflow builds, vulnerability-scans, generates an SBOM, and publishes the image. Review Python base-image and dependency advisories monthly and immediately for critical findings.

Before the first release, an organization owner must allow public package creation if it is restricted. After the initial publish, make the GHCR package public once in its Package settings. The image links itself to this public repository for access management, but GitHub does not automatically inherit repository visibility. Public visibility allows Container Apps to pull without registry credentials.

The image is an independent release artifact: consumer deployments do not build it. When the Python runtime, dependencies, or generic checker code changes, publish a new image release first, then change `backup_integrity_container_image`'s module default to the new immutable tag (preferably its digest) and merge that Terraform change. Consumers that track module `main` then receive the new image through their normal Terraform deployment. Never use a mutable `main` image tag.

The module performs a direct cutover: applying it removes the Automation resources and creates the job. Manually start one execution immediately after deployment, then confirm `Backup integrity check PASSED` in Log Analytics and that the temporary server was deleted.

## Datadog tracking

If the environment already exports Azure Container Apps logs to Datadog, create a log monitor matching `Backup integrity check FAILED` for failure and a freshness monitor matching `Backup integrity check PASSED` for the selected schedule. The log lines include the source server name and never include the database password. The module also creates an Azure Monitor failed-check alert by default; existing action groups can be attached with `backup_integrity_alert_action_group_ids`.
