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

dependency "ecs_backend_sg" {
  config_path = "../ecs_backend"
  
  mock_outputs = {
    security_group_id = "sg-mock-ecs-backend"
  }
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.rds_configs.postgresql,
  {
    vpc_id = dependency.vpc.outputs.id
    security_group_rules = {
      ingress = [
        {
          description              = "PostgreSQL from ECS"
          from_port                = 5432
          to_port                  = 5432
          protocol                 = "tcp"
          source_security_group_id = dependency.ecs_backend_sg.outputs.security_group_id
        }
      ]
      egress = [
        {
          description = "All outbound"
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
        }
      ]
    }
  }
)

