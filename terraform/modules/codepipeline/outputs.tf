output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.pipeline.name
}

output "pipeline_arn" {
  description = "ARN of the CodePipeline"
  value       = aws_codepipeline.pipeline.arn
}

output "artifacts_bucket_name" {
  description = "Name of the S3 artifacts bucket"
  value       = aws_s3_bucket.artifacts.bucket
}

output "artifacts_bucket_arn" {
  description = "ARN of the S3 artifacts bucket"
  value       = aws_s3_bucket.artifacts.arn
}

output "codebuild_project_name" {
  description = "Name of the CodeBuild project"
  value       = aws_codebuild_project.build.name
}

output "codebuild_project_arn" {
  description = "ARN of the CodeBuild project"
  value       = aws_codebuild_project.build.arn
}

output "connection_arn" {
  description = "ARN of the CodeStar connection"
  value       = var.create_connection ? aws_codestarconnections_connection.source[0].arn : var.source_connection_arn
}

output "connection_status" {
  description = "Status of the CodeStar connection"
  value       = var.create_connection ? aws_codestarconnections_connection.source[0].connection_status : null
}