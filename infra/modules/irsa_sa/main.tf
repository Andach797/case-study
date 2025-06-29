data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [var.oidc_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${var.oidc_url}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${var.name_prefix}-sa"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name_prefix}-irsa"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "inline" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${var.bucket_arn}/*"]
    effect    = "Allow"
  }

  # read runtime secrets dynamically
  dynamic "statement" {
    for_each = length(var.secret_arns) == 0 ? [] : [1]
    content {
      actions   = ["secretsmanager:GetSecretValue"]
      resources = var.secret_arns
      effect    = "Allow"
    }
  }

  # lets the app log its identity maybe needed
  statement {
    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
    effect    = "Allow"
  }
}

resource "aws_iam_role_policy" "inline" {
  name   = "${var.name_prefix}-inline"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.inline.json
}

resource "kubernetes_service_account" "this" {
  metadata {
    name      = "${var.name_prefix}-sa"
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this.arn
    }
  }
}
