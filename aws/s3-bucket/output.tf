output "id" {
  description = "ID of the s3 bucket"
  value       = aws_s3_bucket.bucket.id
}

output "arn" {
  description = "ARN of the s3 bucket"
  value       = aws_s3_bucket.bucket.arn
}

output "versioning" {
  description = "ID of the s3 bucket versioning"
  value       = var.versioning ? aws_s3_bucket_versioning.versioning[0].id : null
}
