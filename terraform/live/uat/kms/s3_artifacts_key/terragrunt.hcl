terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/kms?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "kms" {
  path   = find_in_parent_folders("kms.hcl")
  expose = true
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.kms_configs.s3_artifacts_key,
  {
    additional_statements = templatefile("${get_terragrunt_dir()}/additional_statements.tpl", {
      account_id          = include.kms.locals.account_id,
      region              = include.root.locals.vars.aws_region
    })
  }
)
