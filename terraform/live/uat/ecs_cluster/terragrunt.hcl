terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/ecs_cluster?ref=develop"
}

include "root" {
  path = find_in_parent_folders("root.hcl")
  expose = true
}


inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.ecs_configs.cluster
)
