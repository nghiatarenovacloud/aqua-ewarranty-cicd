terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/codestar_connections?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.codestar_connections_configs.github
)
