# Deploy sem chaves: cada repositório assume um papel via OIDC do GitHub,
# restrito ao ambiente GitHub (ex.: aws-dev) daquele repositório.

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
  tags           = var.tags
}

data "aws_iam_policy_document" "deploy_trust" {
  for_each = toset(var.deploy_repositories)
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_owner}/${each.value}:environment:${var.github_environment}"]
    }
  }
}

resource "aws_iam_role" "deploy" {
  for_each             = toset(var.deploy_repositories)
  name                 = "${var.prefix}-deploy-${each.value}"
  assume_role_policy   = data.aws_iam_policy_document.deploy_trust[each.value].json
  max_session_duration = 3600
  tags                 = var.tags
}

# PowerUser cobre ECS, ECR, SQS, SNS, Logs, Secrets... mas não IAM.
resource "aws_iam_role_policy_attachment" "deploy_power_user" {
  for_each   = aws_iam_role.deploy
  role       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# IAM só sobre papéis do próprio projeto.
data "aws_iam_policy_document" "deploy_iam" {
  statement {
    sid = "ManageProjectRoles"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PassRole",
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.prefix}-*"]
  }
}

resource "aws_iam_role_policy" "deploy_iam" {
  for_each = aws_iam_role.deploy
  name     = "project-iam"
  role     = each.value.name
  policy   = data.aws_iam_policy_document.deploy_iam.json
}
