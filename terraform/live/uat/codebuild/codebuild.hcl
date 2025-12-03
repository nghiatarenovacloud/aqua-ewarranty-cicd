locals {
  account_id = get_aws_account_id()
}

dependency "s3_bucket_id_artifacts" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/s3/artifacts"
  
  mock_outputs = {
    id = "mock-artifacts-bucket"
  }
}

