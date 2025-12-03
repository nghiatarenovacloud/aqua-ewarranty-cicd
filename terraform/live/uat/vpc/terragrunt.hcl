terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/vpc?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = merge(
  include.root.locals.vpc_configs,
  include.root.locals.common_resource_config
)

