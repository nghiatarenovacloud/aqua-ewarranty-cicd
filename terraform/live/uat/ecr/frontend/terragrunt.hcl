terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/ecr?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.ecr_configs.frontend,
  {
    lifecycle_policy = jsonencode(include.root.locals.ecr_configs.frontend.lifecycle_policy)
  }
)

