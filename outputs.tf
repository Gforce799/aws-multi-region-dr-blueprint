output "primary_bucket_name" {
  description = "Primary S3 bucket name."
  value       = aws_s3_bucket.primary.id
}

output "replica_bucket_name" {
  description = "Replica S3 bucket name."
  value       = aws_s3_bucket.replica.id
}

output "backup_plan_id" {
  description = "AWS Backup plan ID."
  value       = aws_backup_plan.this.id
}
