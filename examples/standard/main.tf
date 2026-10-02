module "this" {
    source = "../.."

    name        = "multi-region-dr-blueprint"
    environment = "dev"

dr_region                = "us-west-2"
backup_resource_arns     = []
backup_delete_after_days = 45

    tags = {
      Owner      = "platform-team"
      CostCenter = "portfolio"
    }
  }
