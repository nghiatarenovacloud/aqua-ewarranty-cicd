terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/sns?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

locals {
  name       = "${include.root.locals.common_resource_config.prefix}-${include.root.locals.sns_configs.pipeline_notifications.name}"
  account_id = include.root.locals.account_id
  region     = include.root.locals.vars.aws_region
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.sns_configs.pipeline_notifications,
  {
    iam_policy_statements    = templatefile("${get_terragrunt_dir()}/iam_policy_statements.tpl", {
      name                   = local.name,
      account_id             = local.account_id,
      region                 = local.region
    })
  }
)
