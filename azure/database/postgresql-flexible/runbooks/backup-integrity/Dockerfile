# The Debian slim stream presently contains High findings without available
# Debian fixes. This pure-Python workload uses the maintained Alpine stream.
FROM python:3.13-alpine
LABEL org.opencontainers.image.source="https://github.com/THEY-Consulting/they-terraform"
LABEL org.opencontainers.image.description="PostgreSQL backup-integrity checker"
WORKDIR /app
RUN apk upgrade --no-cache
# Install only pre-built wheels from a fully resolved, hash-locked dependency
# set. This prevents source build hooks from running during the image build.
COPY backup-integrity/requirements.lock .
RUN pip install --no-cache-dir --only-binary :all: --require-hashes -r requirements.lock \
    && pip uninstall --yes pip setuptools
COPY db_backup_integrity_check.py .
RUN adduser -D -u 10001 appuser
USER 10001
ENTRYPOINT ["python", "/app/db_backup_integrity_check.py"]
