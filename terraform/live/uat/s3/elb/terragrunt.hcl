terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/s3?ref=v1.0.1"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "s3" {
  path   = find_in_parent_folders("s3.hcl")
  expose = true
}

locals {
  name        = "${include.root.locals.s3_configs.elb.name}-${include.root.locals.vars.aws_region}"
  bucket_name = "${include.root.locals.common_resource_config.prefix}-${local.name}"
}

inputs = merge(
  include.root.locals.common_resource_config,
  {
    name                      = local.name
    bucket_versioning         = include.root.locals.s3_configs.elb.bucket_versioning,
    bucket_policy_data_source = templatefile("${get_terragrunt_dir()}/elb-access-logs-policy.json.tpl", {
      bucket_name             = local.bucket_name
      account_id              = include.s3.locals.account_id
    }),
    force_destroy             = include.root.locals.s3_configs.elb.force_destroy
  }
)
