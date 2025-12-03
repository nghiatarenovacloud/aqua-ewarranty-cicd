locals {
  account_id = get_aws_account_id()
}

dependency "kms_backend" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/kms/cw_key_backend"
  
  mock_outputs = {
    key_arn = "arn:aws:ap-southeast-1:123456789012:key/mock-key-id"
  }
}

dependency "kms_frontend" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/kms/cw_key_frontend"
  
  mock_outputs = {
    key_arn = "arn:aws:ap-southeast-1:123456789012:key/mock-key-id"
  }
}

dependency "s3_artifacts_key" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/kms/s3_artifacts_key"
  
  mock_outputs = {
    key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mock-key-id"
  }
}

dependency "s3"{
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/s3/artifacts"

  mock_outputs = {
    id = "bucket-mock"
    arn = "arn:aws:s3:::bucket-mock"
  }
}

