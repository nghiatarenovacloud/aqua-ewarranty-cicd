[
  {
    Effect = "Allow"
    Action = [
      "kms:Decrypt",
      "kms:Encrypt",
      "kms:GenerateDataKey"
    ]
    Resource = [
      "${kms_cw_key_arn}",
      "${kms_s3_key_arn}"
    ]
  },
  {
    Action = [
      "logs:PutLogEvents",
      "logs:CreateLogStream",
      "logs:CreateLogGroup"
    ]
    Effect = "Allow"
    Resource = [
      "arn:aws:logs:*:*:log-group:/aws/codebuild/${name}",
      "arn:aws:logs:*:*:log-group:/aws/codebuild/${name}:*"
    ]
  },
  {
    Action = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
      "s3:List*",
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    Effect = "Allow"
    Resource = [
      "${s3_artifact_bucket_arn}/*",
      "${s3_artifact_bucket_arn}"
    ]
  },
  {
    Action = [
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:InitiateLayerUpload",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetAuthorizationToken",
      "ecr:CompleteLayerUpload",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability"
    ]
    Effect = "Allow"
    Resource = ["*"]
  },
  {
    Action = [
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
      "ecs:DescribeTaskDefinition",
      "ecs:DescribeServices",
      "ecs:DescribeClusters"
    ]
    Effect = "Allow"
    Resource = ["*"]
  },
  {
    Action = [
      "secretsmanager:ListSecrets",
      "secretsmanager:GetSecretValue",
      "rds:DescribeDBInstances"
    ]
    Effect = "Allow"
    Resource = ["*"]
  },
  {
    Action = ["iam:PassRole"]
    Effect = "Allow"
    Resource = [
      "${frontend_task_execution_role}",
      "${frontend_task_role_arn}"
    ]
    Condition = {
      "StringEquals" = {
        "iam:PassedToService" = "ecs-tasks.amazonaws.com"
      }
    }
  }
]
