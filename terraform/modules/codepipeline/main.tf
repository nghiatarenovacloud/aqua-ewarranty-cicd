resource "aws_codestarconnections_connection" "source" {
  count         = var.create_connection ? 1 : 0
  name          = "${var.prefix}-${var.name}-connection"
  provider_type = var.connection_provider_type
  tags          = var.tags
}

resource "aws_codebuild_project" "build" {
  name         = "${var.prefix}-${var.name}-build"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type    = var.build_compute_type
    image          = var.build_image
    type           = "LINUX_CONTAINER"
    privileged_mode = true
    
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = data.aws_region.current.id
    }
    
    environment_variable {
      name  = "AWS_ACCOUNT_ID"
      value = data.aws_caller_identity.current.account_id
    }
    
    environment_variable {
      name  = "IMAGE_REPO_NAME"
      value = var.ecr_repository_name
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = var.buildspec_path
  }

  tags = var.tags
}

resource "aws_codepipeline" "pipeline" {
  name          = "${var.prefix}-${var.name}"
  role_arn      = aws_iam_role.codepipeline.arn
  pipeline_type = "V2"

  artifact_store {
    location = aws_s3_bucket.artifacts.bucket
    type     = "S3"
  }

  lifecycle {
    ignore_changes = [
      # Ignore changes that might trigger unwanted executions
      stage[0].action[0].configuration["DetectChanges"]
    ]
  }



  stage {
    name = "Source"

    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        ConnectionArn               = var.create_connection ? aws_codestarconnections_connection.source[0].arn : var.source_connection_arn
        FullRepositoryId           = var.repository_id
        BranchName                 = var.branch_name
        DetectChanges              = tostring(var.auto_start_pipeline)
        OutputArtifactFormat       = "CODE_ZIP"
      }
    }
  }

  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = aws_codebuild_project.build.name
      }
    }
  }

  stage {
    name = "Deploy"

    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"

      configuration = {
        ApplicationName     = var.codedeploy_application_name
        DeploymentGroupName = var.codedeploy_deployment_group_name
      }
    }
  }

  tags = var.tags
}