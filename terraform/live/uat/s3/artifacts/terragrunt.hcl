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
  name        = "${include.root.locals.s3_configs.artifacts.name}-${include.root.locals.vars.aws_region}"
  bucket_name = "${include.root.locals.common_resource_config.prefix}-${local.name}"
}

inputs = merge(
  include.root.locals.common_resource_config,
  {
    name               = local.name
    bucket_versioning  = include.root.locals.s3_configs.artifacts.bucket_versioning
    encryption_type    = include.root.locals.s3_configs.artifacts.encryption_type
    force_destroy      = include.root.locals.s3_configs.artifacts.force_destroy
  }
)