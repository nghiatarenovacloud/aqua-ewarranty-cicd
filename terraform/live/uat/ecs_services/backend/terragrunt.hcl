terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/ecs_services?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "ecs_services" {
  path           = "../ecs_services.hcl"
  merge_strategy = "deep"
}

dependency "ecs_backend_sg" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/sg/ecs_backend"
  
  mock_outputs = {
    security_group_id = "sg-mock-ecs-backend"
  }
}

dependency "ecr_backend" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecr/backend"
  
  mock_outputs = {
    repository_url = "mock-backend-repo"
  }
}

dependency "rds_secret" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/rds/postgresql"
  
  mock_outputs = {
    rds_db_secret = "arn:aws:secretsmanager:ap-southeast-1:123456789012:secret:mock-secret-name"
  } 
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.ecs_configs.services.backend,
  {
    # Cluster configuration
    cluster_id = dependency.ecs_cluster.outputs.cluster_id
    cluster_name = dependency.ecs_cluster.outputs.cluster_name
    service_discovery_namespace_arn = dependency.ecs_cluster.outputs.service_discovery_namespace_arn
    # Override service configuration with runtime values
    service = merge(
      include.root.locals.ecs_configs.services.backend.service,
      {
        subnets = dependency.vpc.outputs.app_subnet_ids
        security_groups = [dependency.ecs_backend_sg.outputs.security_group_id]
        target_group_arn = dependency.backend_alb.outputs.target_group_arns["backend-blue"]
      }
    )
    #Override container configuration with rds secret name
    containers = [
      merge(
        include.root.locals.ecs_configs.services.backend.containers[0],
        {
          secrets = [
            {
              name = "DATABASE_URL"
              valueFrom = dependency.rds_secret.outputs.rds_db_secret
            }
          ]
        }
      )
    ]
  }
)

