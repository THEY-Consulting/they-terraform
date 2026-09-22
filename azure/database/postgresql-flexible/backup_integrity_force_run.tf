# Allows a manual execution to exercise the full restore/check/cleanup path even
# when the UTC schedule interval would normally skip that execution.
variable "backup_integrity_force_run" {
  description = "Bypass the backup-integrity schedule interval for a deliberate manual test run. Keep false for normal scheduled operation."
  type        = bool
  default     = false
}
