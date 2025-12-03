terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/codepipeline?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "codepipeline" {
  path            = find_in_parent_folders("codepipeline.hcl")
  expose          = true
  merge_strategy  = "deep"
}

dependency "s3" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/s3/artifacts"

  mock_outputs = {
    id = "bucket-mock"
    arn = "arn:aws:s3:::bucket-mock"
  }
}

dependency "kms" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/kms/s3_artifacts_key"

  mock_outputs = {
    key_arn = "arn:aws:kms:ap-southeast-1:123456789012:key/mock-key-id"
  }
}

dependency "codebuild_build" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/codebuild/frontend"

  mock_outputs = {
    project_name = "build1-mock"
    project_arn  = "arn:aws:codebuild:ap-southeast-1:123456789012:project/frontend-mock"
  }
}

dependency "codedeploy_deploy" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/codedeploy/frontend"

  mock_outputs = {
    application_name = "frontend-mock"
    application_arn  = "arn:aws:codedeploy:ap-southeast-1:123456789012:application/frontend-mock"
  }
}

dependency "sns" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/sns/pipeline_approval"

  mock_outputs = {
    topic_arn = "arn:aws:sns:ap-southeast-1:123456789012:mock-topic"
  }
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.codepipeline_configs.frontend_pipeline,
  {
    artifact_bucket_name = dependency.s3.outputs.id
    kms_key_id           = dependency.kms.outputs.key_arn
    approval_actions     = {
      uat_approval = merge(
        include.root.locals.codepipeline_configs.frontend_pipeline.approval_actions.uat_approval,
        {
          sns_topic_arn = dependency.sns.outputs.topic_arn
        }
      )
    }
    stages               = [
      for stage in include.root.locals.codepipeline_configs.frontend_pipeline.stages : merge(stage, {
        actions = [
          for action in stage.actions : merge(action, {
            configuration = merge(
              action.configuration,
              contains(keys(action.configuration), "ConnectionArn") ? {
                ConnectionArn = dependency.codestar_connections.outputs.connection_arn
              } : {},
              contains(keys(action.configuration), "ProjectName") ? {
                ProjectName = action.configuration.ProjectName == "dependency.codebuild_build.outputs.project_arn" ? dependency.codebuild_build.outputs.project_name : action.configuration.ProjectName == "dependency.codedeploy_deploy.outputs.project_arn" ? dependency.codedeploy_deploy.outputs.project_name : action.configuration.ProjectName
              } : {}
            )
          })
        ]
      })
    ]
    iam_policy_statements = templatefile("${get_terragrunt_dir()}/iam_policy_statements.tpl", {
      s3_artifact_bucket_arn = dependency.s3.outputs.arn,
      build_project_arn      = dependency.codebuild_build.outputs.project_arn,
      deploy_project_arn     = dependency.codedeploy_deploy.outputs.application_arn,
      kms_key_arn            = dependency.kms.outputs.key_arn,
      connection_arn         = dependency.codestar_connections.outputs.connection_arn,
      topic_arn              = dependency.sns.outputs.topic_arn
    })
  }
)
