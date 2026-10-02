data "aws_caller_identity" "current" {}

resource "aws_kms_key" "primary" {
  description         = "Primary DR KMS key for ${local.name_prefix}"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_kms_key" "dr" {
  provider            = aws.dr
  description         = "Secondary DR KMS key for ${local.name_prefix}"
  enable_key_rotation = true
  tags                = local.tags
}

resource "aws_s3_bucket" "primary" {
  bucket = "${local.name_prefix}-primary-${data.aws_caller_identity.current.account_id}"
  tags   = local.tags
}

resource "aws_s3_bucket" "replica" {
  provider = aws.dr
  bucket   = "${local.name_prefix}-replica-${data.aws_caller_identity.current.account_id}"
  tags     = local.tags
}

resource "aws_s3_bucket_versioning" "primary" {
  bucket = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.dr
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.primary.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "replica" {
  provider = aws.dr
  bucket   = aws_s3_bucket.replica.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.dr.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

data "aws_iam_policy_document" "replication_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication" {
  name               = "${local.name_prefix}-s3-replication"
  assume_role_policy = data.aws_iam_policy_document.replication_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "replication" {
  name = "${local.name_prefix}-s3-replication"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Resource = aws_s3_bucket.primary.arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionTagging"
        ]
        Resource = "${aws_s3_bucket.primary.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.replica.arn}/*"
      },
      {
        Effect = "Allow"
        Action = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.primary.arn
      },
      {
        Effect = "Allow"
        Action = ["kms:Encrypt", "kms:GenerateDataKey"]
        Resource = aws_kms_key.dr.arn
      }
    ]
  })
}

resource "aws_s3_bucket_replication_configuration" "primary" {
  bucket = aws_s3_bucket.primary.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-encrypted-objects"
    status = "Enabled"

    filter {}

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD_IA"

      encryption_configuration {
        replica_kms_key_id = aws_kms_key.dr.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica
  ]
}

resource "aws_backup_vault" "primary" {
  name        = "${local.name_prefix}-primary"
  kms_key_arn = aws_kms_key.primary.arn
  tags        = local.tags
}

resource "aws_backup_vault" "dr" {
  provider    = aws.dr
  name        = "${local.name_prefix}-dr"
  kms_key_arn = aws_kms_key.dr.arn
  tags        = local.tags
}

resource "aws_backup_plan" "this" {
  name = local.name_prefix
  tags = local.tags

  rule {
    rule_name         = "daily-copy-to-dr"
    target_vault_name = aws_backup_vault.primary.name
    schedule          = var.backup_schedule

    lifecycle {
      delete_after = var.backup_delete_after_days
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.dr.arn

      lifecycle {
        delete_after = var.backup_delete_after_days * 2
      }
    }
  }
}

data "aws_iam_policy_document" "backup_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "backup" {
  name               = "${local.name_prefix}-backup"
  assume_role_policy = data.aws_iam_policy_document.backup_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy_attachment" "backup" {
  role       = aws_iam_role.backup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}

resource "aws_backup_selection" "this" {
  count        = length(var.backup_resource_arns) > 0 ? 1 : 0
  iam_role_arn = aws_iam_role.backup.arn
  name         = "${local.name_prefix}-resources"
  plan_id      = aws_backup_plan.this.id
  resources    = var.backup_resource_arns
}

resource "aws_route53_health_check" "primary" {
  count             = var.primary_endpoint_fqdn != "" ? 1 : 0
  fqdn              = var.primary_endpoint_fqdn
  port              = 443
  type              = "HTTPS"
  resource_path     = "/"
  failure_threshold = 3
  request_interval  = 30
  tags              = local.tags
}
