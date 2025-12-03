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

dependency "frontend_alb" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/elb/frontend_alb"
  
  mock_outputs = {
    target_group_arns = {
      "frontend-blue"  = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:targetgroup/frontend-blue/1234567890abcdef"
      "frontend-green" = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:targetgroup/frontend-green/abcdef1234567890"
    }
  }
}


dependency "ecr_frontend" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecr/frontend"
  
  mock_outputs = {
    repository_url = "mock-frontend-repo"
  }
}

dependency "ecs_frontend_sg" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/sg/ecs_frontend"
  
  mock_outputs = {
    security_group_id = "sg-mock-ecs-frontend"
  }
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.ecs_configs.services.frontend,
  {
    # Cluster configuration
    cluster_id = dependency.ecs_cluster.outputs.cluster_id
    cluster_name = dependency.ecs_cluster.outputs.cluster_name
    service_discovery_namespace_arn = dependency.ecs_cluster.outputs.service_discovery_namespace_arn
    # Override service configuration with runtime values
    service = merge(
      include.root.locals.ecs_configs.services.frontend.service,
      {
        subnets = dependency.vpc.outputs.app_subnet_ids
        security_groups = [dependency.ecs_frontend_sg.outputs.security_group_id]
        target_group_arn = dependency.frontend_alb.outputs.target_group_arns["frontend-blue"]
      }
    )
    # Override container configuration with backend ALB URL
    containers = [
      merge(
        include.root.locals.ecs_configs.services.frontend.containers[0],
        {
          environment = [
            {
              name = "NEXT_PUBLIC_API_URL"
              value = "http://${dependency.backend_alb.outputs.lb_dns_name}:8080"
            }
          ]
        }
      )
    ]
  }
)

