terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/sg?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "sg" {
  path            = find_in_parent_folders("sg.hcl")
  merge_strategy  = "deep"
}

inputs = merge(
  include.root.locals.common_resource_config,
  {
    name                 = include.root.locals.elb_configs.backend_alb.name
    vpc_id               = dependency.vpc.outputs.id
    security_group_rules = include.root.locals.elb_configs.backend_alb.security_group_rules
  }
)
