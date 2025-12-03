terragrunt_version_constraint = ">= v0.83.0"
terraform_version_constraint = ">= v1.11.0"

locals {
  account_id = get_aws_account_id()
  vars = yamldecode(file("terraform.auto.tfvars.yaml"))

  common_tags = {
    "${upper(local.vars.prefix)}:Project"     = local.vars.project
    "${upper(local.vars.prefix)}:Workload"    = local.vars.workload
    "${upper(local.vars.prefix)}:Environment" = local.vars.env
    "${upper(local.vars.prefix)}:Owner"       = local.vars.owner
    Owner                                     = get_env("BUILD_USER", local.vars.owner) # for devtest
  }

  # aqua-aws-app-uat
  ## prefix = aqua
  ## project = cicd
  ## workload = app
  ## env = uat
  base_prefix = "${local.vars.prefix}-${local.vars.project}-${local.vars.workload}-${local.vars.env}"
  
  common_resource_config = {
    prefix               = local.base_prefix
    tags                 = local.common_tags
    vars                 = local.vars
  }

  vpc_configs = local.vars.vpc_configs

  vpc_endpoints = {
    gateway_endpoints = {
      for k, v in local.vars.vpc_endpoints.gateway_endpoints : k => {
        service_name    = "com.amazonaws.${local.vars.aws_region}.${v.service_name}"
        route_table_ids = ["db", "app"]  # Will be resolved in terragrunt
      }
    }
  }

  ecr_configs = local.vars.ecr_configs

  s3_configs = local.vars.s3_configs

  elb_configs = local.vars.elb_configs

  ecs_configs = local.vars.ecs_configs

  codedeploy_configs = local.vars.codedeploy_configs

  rds_configs = local.vars.rds_configs

  kms_configs = local.vars.kms_configs

  codebuild_configs = local.vars.codebuild_configs

  sns_configs = local.vars.sns_configs

  codestar_connections_configs = local.vars.codestar_connections_configs

  codestar_notifications_configs = local.vars.codestar_notifications_configs
  
  codepipeline_configs = local.vars.codepipeline_configs
}

remote_state {
  backend = "s3"

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite"
  }

  config = {
    bucket         = "${local.base_prefix}-${local.vars.aws_region}"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = local.vars.aws_region
    encrypt        = true
    dynamodb_table = "${local.base_prefix}-state-lock"
    s3_bucket_tags      = local.common_tags
    dynamodb_table_tags = local.common_tags
  }
}

generate "versions" {
  path      = "versions.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.3.0"
    }
  }
}

provider "aws" {
  region = "${local.vars.aws_region}"
}
EOF
}
