terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/elb?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "elb" {
  path           = find_in_parent_folders("elb.hcl")
  merge_strategy = "deep"
}

dependency "frontend_alb_sg" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/sg/frontend_alb"
  mock_outputs = {
    security_group_id = "sg-mock-frontend-alb"
  }
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.elb_configs.frontend_alb,
  {
    # Override with actual values from dependencies
    vpc_id          = dependency.vpc.outputs.id
    subnets         = dependency.vpc.outputs.gw_subnet_ids
    security_groups = [dependency.frontend_alb_sg.outputs.security_group_id]
    access_logs_bucket = dependency.s3_elb.outputs.id
  }
)
