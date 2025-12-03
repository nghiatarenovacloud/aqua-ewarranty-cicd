terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/codebuild?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "codebuild" {
  path   = find_in_parent_folders("codebuild.hcl")
  expose = true
}

dependency "kms_frontend" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/kms/cw_key_frontend"
  
  mock_outputs = {
    key_arn = "arn:aws:ap-southeast-1:123456789012:key/mock-key-id"
  }
}

dependency "frontend_ecr_name" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecr/frontend"
  
  mock_outputs = {
    repository_name = "frontend"
  }
} 

dependency "frontend_task_execution_role" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecs_services/frontend"
  
  mock_outputs = {
    execution_role_arn = "arn:aws:iam::123456789012:role/mock-frontend-execution-role"
  }
}

dependency "frontend_task_role_arn" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/ecs_services/frontend"
  
  mock_outputs = {
    task_role_arn = "arn:aws:iam::123456789012:role/mock-frontend-task-role"
  }
}

locals {
  name       = "${include.root.locals.common_resource_config.prefix}-${include.root.locals.codebuild_configs.frontend.name}"
  account_id = include.codebuild.locals.account_id
  region     = include.root.locals.vars.aws_region
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.codebuild_configs.frontend,
  {
    kms_key_arn           = dependency.kms_frontend.outputs.key_arn
    iam_policy_statements = templatefile("${get_terragrunt_dir()}/iam_policy_statements.tpl", {
      name                = local.name,
      account_id          = local.account_id,
      kms_cw_key_arn         = dependency.kms_frontend.outputs.key_arn,
      kms_s3_key_arn      = dependency.s3_artifacts_key.outputs.key_arn,
      s3_artifact_bucket_arn = dependency.s3.outputs.arn,
      frontend_task_execution_role = dependency.frontend_task_execution_role.outputs.execution_role_arn
      frontend_task_role_arn      = dependency.frontend_task_role_arn.outputs.task_role_arn
    })

    buildspec_file        = "${get_terragrunt_dir()}/buildspec_frontend.yml"

    environment_variables = {
      AWS_DEFAULT_REGION = {
        value = local.region
        type  = "PLAINTEXT"
      }
      AWS_ACCOUNT_ID = {
        value = local.account_id
        type  = "PLAINTEXT"
      }
      IMAGE_REPO_NAME = {
        value = dependency.frontend_ecr_name.outputs.repository_name
        type  = "PLAINTEXT"
      }
    }
  }
)

