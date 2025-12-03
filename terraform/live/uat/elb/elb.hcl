dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/vpc"
  
  mock_outputs = {
    id              = "vpc-mock"
    gw_subnet_ids  = ["subnet-mock1", "subnet-mock2"]
    app_subnet_ids = ["subnet-mock3", "subnet-mock4"]
  }
}

dependency "s3_elb" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/s3/elb"
  
  mock_outputs = {
    id = "mock-elb-bucket"
  }
}

locals {
  account_id = get_aws_account_id()
}
