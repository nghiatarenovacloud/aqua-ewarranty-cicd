dependency "vpc" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/vpc"
  
  mock_outputs = {
    id = "vpc-mock"
  }
}

