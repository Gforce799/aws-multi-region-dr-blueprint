variable "aws_region" {
  description = "AWS region used for primary resources."
  type        = string
  default     = "us-east-1"
}

variable "name" {
  description = "Short workload name used for resource naming."
  type        = string
  default     = "multi-region-dr-blueprint"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,32}$", var.name))
    error_message = "Use 3-32 lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "stage", "prod"], var.environment)
    error_message = "Environment must be dev, test, stage, or prod."
  }
}

variable "tags" {
  description = "Additional tags merged into all supported resources."
  type        = map(string)
  default     = {}
}

variable "dr_region" {
  description = "Secondary AWS region for disaster recovery resources."
  type        = string
  default     = "us-west-2"
}

variable "backup_resource_arns" {
  description = "Resource ARNs protected by AWS Backup."
  type        = list(string)
  default     = []
}

variable "backup_schedule" {
  description = "AWS Backup cron expression."
  type        = string
  default     = "cron(0 5 ? * * *)"
}

variable "backup_delete_after_days" {
  description = "Days before recovery points are deleted."
  type        = number
  default     = 35
}

variable "primary_endpoint_fqdn" {
  description = "Optional FQDN for Route 53 health check."
  type        = string
  default     = ""
}
