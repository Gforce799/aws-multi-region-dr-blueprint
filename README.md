# AWS Multi-Region DR Blueprint

    A disaster-recovery blueprint with primary and secondary region providers, encrypted backup vaults, backup copy actions, S3 cross-region replication, and optional Route 53 health checks.

    **Portfolio size:** Large

    ## AWS services covered

    - AWS Backup
- Amazon S3 replication
- AWS KMS
- IAM
- Route 53 health checks
- Multi-region provider aliases

    ## Enterprise controls demonstrated

    - Provider pinning and repeatable Terraform workflows.
    - Encryption at rest with KMS where the service supports customer managed keys.
    - Least-privilege IAM roles and narrowly scoped service policies.
    - Consistent tagging, naming, retention, and environment separation.
    - CI checks for formatting, validation, linting, and IaC security scanning.
    - Security documentation, architecture notes, and reusable module structure.

    ## Quick start

    ```bash
    terraform init
    terraform fmt -recursive
    terraform validate
    terraform plan -out=tfplan
    ```

    ## Production hardening checklist

    - Replace placeholder CIDR ranges, ARNs, domain names, and retention windows.
    - Connect remote state with state locking before team usage.
    - Review every IAM trust relationship against your account structure.
    - Enable branch protection and required CI checks in GitHub.
    - Run a cost estimate before deployment to a live AWS account.

    ## Repository intent

    This repository is designed as a professional AWS infrastructure template.
    It favors clear architecture, security defaults, and reviewable Terraform
    over one-click deployment magic.
