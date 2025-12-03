[
  {
    Effect = "Allow"
    Action = [
      "s3:GetBucketVersioning",
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject"
    ]
    Resource = [
      "${s3_artifact_bucket_arn}",
      "${s3_artifact_bucket_arn}/*"
    ]
  },
  {
    Effect = "Allow"
    Action = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]
    Resource = [
      "${build_project_arn}",
      "${deploy_project_arn}"
    ]
  },
  {
    Effect = "Allow"
    Action = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
      "kms:DescribeKey"
    ]
    Resource = ["${kms_key_arn}"]
  },
  {
    Effect = "Allow"
    Action = [
      "codestar-connections:UseConnection"
    ]
    Resource = ["${connection_arn}"]
  },
  {
    Effect = "Allow"
    Action = [
      "sns:Publish"
    ]
    Resource = ["${topic_arn}"]
  }
]
