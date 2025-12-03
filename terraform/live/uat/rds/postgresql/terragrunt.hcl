terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/rds?ref=v1.0.1"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/vpc"
  mock_outputs = {
    id = "vpc-mock"
    db_subnet_ids = ["subnet-mock1", "subnet-mock2"]
  }
}

dependency "sg_rds_postgresql" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/sg/rds-postgresql"
  mock_outputs = {
    security_group_id = "sg-mock"
  }
}

locals {
  conf = include.root.locals.rds_configs.postgresql
}

inputs = merge(
  include.root.locals.common_resource_config,
  local.conf,
  {
    db_subnet_ids      = dependency.vpc.outputs.db_subnet_ids
    vpc_id             = dependency.vpc.outputs.id
    security_group_id  = dependency.sg_rds_postgresql.outputs.security_group_id
  }
)
