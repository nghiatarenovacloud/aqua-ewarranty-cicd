terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/vpc_endpoint?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "vpc" {
  config_path = "../vpc"
  
  mock_outputs = {
    id                 = "vpc-mock"
    vpc_cidr_block     = "10.200.16.0/20"
    app_route_table_id = "rtb-mock1"
    db_route_table_id  = "rtb-mock2"
  }
}

inputs = merge(
  include.root.locals.common_resource_config,
  {
    vpc_id         = dependency.vpc.outputs.id
    vpc_cidr_block = dependency.vpc.outputs.vpc_cidr_block
    
    # Gateway Endpoints from YAML config
    gateway_endpoints = {
      for k, v in include.root.locals.vpc_endpoints.gateway_endpoints : k => {
        service_name    = v.service_name
        route_table_ids = [dependency.vpc.outputs.db_route_table_id, dependency.vpc.outputs.app_route_table_id]
      }
    }
  }
)
