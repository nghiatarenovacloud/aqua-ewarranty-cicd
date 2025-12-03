# Shared CodeDeploy configuration
dependency "ecs_cluster" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecs_cluster"
  mock_outputs = {
    cluster_name = "cluster-mock"
  }
}

dependency "ecs_frontend" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecs_services/frontend"
  mock_outputs = {
    service_name = "frontend-mock"
  }
}

dependency "frontend_alb" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/elb/frontend_alb"
  mock_outputs = {
    target_groups = {
      "frontend-blue" = {
        name = "frontend-blue-tg"
      }
      "frontend-green" = {
        name = "frontend-green-tg"
      }
    }
    listener_arns = {
      "https" = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:listener/app/frontend-alb/3333333333333333/4444444444444444"
    }
  }
}
