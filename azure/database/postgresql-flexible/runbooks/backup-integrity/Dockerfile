# The Debian slim stream presently contains High findings without available
# Debian fixes. This pure-Python workload uses the maintained Alpine stream.
FROM python:3.13-alpine
LABEL org.opencontainers.image.source="https://github.com/THEY-Consulting/they-terraform"
LABEL org.opencontainers.image.description="PostgreSQL backup-integrity checker"
WORKDIR /app
RUN apk upgrade --no-cache
COPY backup-integrity/requirements.txt .
# pip and setuptools are build-only; remove their vendored vulnerable code from
# the runtime image after installing the pure-Python dependency.
RUN pip install --no-cache-dir --upgrade pip setuptools \
    && pip install --no-cache-dir -r requirements.txt \
    && pip uninstall --yes pip setuptools
COPY db_backup_integrity_check.py .
RUN adduser -D -u 10001 appuser
USER 10001
ENTRYPOINT ["python", "/app/db_backup_integrity_check.py"]
