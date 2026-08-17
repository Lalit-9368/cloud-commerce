
data "aws_iam_openid_connect_provider" "github_actions" {
  arn = "arn:aws:iam::814383264015:oidc-provider/token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    sid    = "GitHubActionsOIDC"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"

      identifiers = [
        data.aws_iam_openid_connect_provider.github_actions.arn
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"

      values = [
        "sts.amazonaws.com"
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:Lalit-9368/cloud-commerce:environment:production"
      ]
    }
  }
}

# ============================================================
# GitHub Actions Deployment Role
# ============================================================

resource "aws_iam_role" "github_actions_deploy" {
  name = "GitHubActionsCloudCommerceDeploy"

  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# ============================================================
# GitHub Actions ECR Policy
# ============================================================

resource "aws_iam_policy" "github_actions_ecr" {
  name        = "GitHubActionsCloudCommerceECR"
  description = "ECR permissions for Cloud Commerce GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ECRAuthorization"
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      {
        Sid    = "ECRImageOperations"
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeImages",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]

        Resource = [
          "arn:aws:ecr:us-east-1:814383264015:repository/cloud-commerce-frontend",
          "arn:aws:ecr:us-east-1:814383264015:repository/cloud-commerce-auth-service",
          "arn:aws:ecr:us-east-1:814383264015:repository/cloud-commerce-catalog-service",
          "arn:aws:ecr:us-east-1:814383264015:repository/cloud-commerce-checkout-service",
          "arn:aws:ecr:us-east-1:814383264015:repository/cloud-commerce-payment-service"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_ecr" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

# ============================================================
# GitHub Actions EKS Policy
# ============================================================

resource "aws_iam_policy" "github_actions_eks" {
  name        = "GitHubActionsCloudCommerceEKS"
  description = "EKS access required by Cloud Commerce GitHub Actions"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EKSDescribeCluster"
        Effect = "Allow"

        Action = [
          "eks:DescribeCluster"
        ]

        Resource = "arn:aws:eks:us-east-1:814383264015:cluster/cloud-commerce-prod"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_eks" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_eks.arn
}