FROM python:3.13.7-slim
LABEL org.opencontainers.image.source="https://github.com/THEY-Consulting/they-terraform"
LABEL org.opencontainers.image.description="PostgreSQL backup-integrity checker"
WORKDIR /app
COPY backup-integrity/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY db_backup_integrity_check.py .
RUN useradd --create-home --uid 10001 appuser
USER 10001
ENTRYPOINT ["python", "/app/db_backup_integrity_check.py"]
