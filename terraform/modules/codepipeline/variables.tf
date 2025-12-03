variable "prefix" {
  description = "Prefix used for naming resources"
  type        = string
}

variable "name" {
  description = "The name of the CodePipeline"
  type        = string
}

variable "tags" {
  description = "Optional Tags"
  type        = map(string)
  default     = {}
}

variable "create_connection" {
  description = "Whether to create a new CodeStar connection"
  type        = bool
  default     = false
}

variable "connection_provider_type" {
  description = "Provider type for CodeStar connection (GitHub, GitLab, Bitbucket)"
  type        = string
  default     = "GitHub"
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
  type        = string
  default     = ""
}

variable "codedeploy_application_name" {
  description = "Name of the CodeDeploy application"
  type        = string
  default     = ""
}

variable "codedeploy_deployment_group_name" {
  description = "Name of the CodeDeploy deployment group"
  type        = string
  default     = ""
}

variable "source_connection_arn" {
  description = "ARN of existing CodeStar connection (required if create_connection = false)"
  type        = string
  default     = null

  validation {
    condition     = var.create_connection || var.source_connection_arn != null
    error_message = "Either create_connection must be true or source_connection_arn must be provided."
  }
}

variable "repository_id" {
  description = "Repository ID in format owner/repo-name"
  type        = string
}

variable "branch_name" {
  description = "Branch name to trigger the pipeline"
  type        = string
  default     = "main"
}

variable "build_compute_type" {
  description = "CodeBuild compute type"
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
}

variable "build_image" {
  description = "CodeBuild Docker image"
  type        = string
  default     = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
}

variable "buildspec_path" {
  description = "Path to buildspec file"
  type        = string
  default     = "buildspec.yml"
}

variable "auto_start_pipeline" {
  description = "Whether to detect changes and auto-trigger pipeline"
  type        = bool
  default     = false
}

variable "enable_multi_service" {
  description = "Enable multi-service pipeline"
  type        = bool
  default     = false
}

variable "ecr_repositories" {
  description = "Map of ECR repository URLs for multi-service"
  type        = map(string)
  default     = {}
}

variable "ecs_cluster_name" {
  description = "ECS cluster name for deployments"
  type        = string
  default     = ""
}

variable "project" {
  description = "Project name"
  type        = string
  default     = ""
}

variable "workload" {
  description = "Workload name"
  type        = string
  default     = ""
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = ""
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = ""
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
  default     = ""
}

variable "github_owner" {
  description = "GitHub owner for multi-service pipeline"
  type        = string
  default     = ""
}

variable "github_repo" {
  description = "GitHub repository for multi-service pipeline"
  type        = string
  default     = ""
}

variable "github_branch" {
  description = "GitHub branch for multi-service pipeline"
  type        = string
  default     = "main"
}

variable "github_token" {
  description = "GitHub token for multi-service pipeline"
  type        = string
  default     = ""
}