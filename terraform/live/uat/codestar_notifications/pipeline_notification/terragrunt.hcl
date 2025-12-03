terraform {
  source = "github.com/renova-cloud/renova-iac.git//terraform/modules/codestar_notifications?ref=develop"
}

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

dependency "codepipeline" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/codepipeline/frontend_pipeline"
  
  mock_outputs = {
    pipeline_arn = "arn:aws:codepipeline:ap-southeast-1:123456789012:pipeline-mock"
  }
}

dependency "sns" {
  config_path = "${dirname(find_in_parent_folders("root.hcl"))}/sns/pipeline_notifications"
  
  mock_outputs = {
    topic_arn = "arn:aws:sns:ap-southeast-1:123456789012:sns-mock"
  }
}

inputs = merge(
  include.root.locals.common_resource_config,
  include.root.locals.codestar_notifications_configs.pipeline_notification,
  {
    resource_arn = dependency.codepipeline.outputs.pipeline_arn,
    targets      = [
      for target in include.root.locals.codestar_notifications_configs.pipeline_notification.targets:
        merge(
          target,
          {
            address = dependency.sns.outputs.topic_arn
          }
        )
    ]
  }
)
