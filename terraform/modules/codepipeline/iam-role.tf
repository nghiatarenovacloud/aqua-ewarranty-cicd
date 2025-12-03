resource "aws_iam_role" "codepipeline" {
  name               = "${var.prefix}-${var.name}-codepipeline-role"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "${var.prefix}-${var.name}-codepipeline-policy"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline_policy.json
}

resource "aws_iam_role" "codebuild" {
  name               = "${var.prefix}-${var.name}-codebuild-role"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${var.prefix}-${var.name}-codebuild-policy"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild_policy.json
}