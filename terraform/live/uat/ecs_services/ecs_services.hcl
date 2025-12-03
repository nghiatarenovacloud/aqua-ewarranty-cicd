dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/vpc"
  mock_outputs = {
    id              = "vpc-mock"
    app_subnet_ids = ["subnet-mock1", "subnet-mock2"]
  }
}

dependency "ecs_cluster" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecs_cluster"
  
  mock_outputs = {
    cluster_id   = "ecs-cluster-mock-id"
    cluster_name = "ecs-cluster-mock-name"
    service_discovery_namespace_arn = "arn:aws:servicediscovery:mock"
  }
}

dependency "backend_alb" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/elb/backend_alb"
  
  mock_outputs = {
    target_group_arns = {
      "backend-blue"  = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:targetgroup/backend-blue/1234567890abcdef"
      "backend-green" = "arn:aws:elasticloadbalancing:ap-southeast-1:123456789012:targetgroup/backend-green/abcdef1234567890"
    }
    lb_dns_name = "backend-alb-mock.elb.amazonaws.com"
  }
}
