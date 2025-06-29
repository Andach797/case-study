locals {
  repo = "${var.repo_owner}/${var.repo_name}"
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "gha_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.repo}:*"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.role_name != "" ? var.role_name : "${replace(local.repo, "/", "-")}-tf"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "terraform_policy" {
  statement {
    sid    = "S3State"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "arn:aws:s3:::${var.backend_bucket}",
      "arn:aws:s3:::${var.backend_bucket}/*",
    ]
  }

  statement {
    sid    = "DynamoDBLock"
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      "arn:aws:dynamodb:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:table/${var.dynamodb_table_name}"
    ]
  }

  statement {
    sid    = "TerraformWide"
    effect = "Allow"
    actions = [
      "ec2:*",
      "eks:*",
      "iam:*",
      "ecr:*",
      "secretsmanager:*",
      "elasticfilesystem:*",
      "cloudwatch:*",
    ]
    resources = ["*"]
  }

  statement {
    sid    = "CsvBucketAdmin"
    effect = "Allow"
    actions = [
      "s3:*"
    ]
    resources = [
      "arn:aws:s3:::${var.csv_bucket}",
      "arn:aws:s3:::${var.csv_bucket}/*"
    ]
  }

  # CloudWatch Logs permissions for vpc flow logs etc.
  statement {
    sid       = "CloudWatchLogsRead"
    effect    = "Allow"
    actions   = ["logs:*"]
    resources = ["*"]
  }
}


resource "aws_iam_role_policy" "inline" {
  name   = "${aws_iam_role.this.name}-tf-policy"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.terraform_policy.json
}
