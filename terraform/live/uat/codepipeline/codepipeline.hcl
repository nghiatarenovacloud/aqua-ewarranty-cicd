dependency "codestar_connections" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/codestar_connections/github"
  
  mock_outputs = {
    connection_arn = "arn:aws:codestar-connections:ap-southeast-1:123456789012:connection/mock-connection-id"
  }
}
