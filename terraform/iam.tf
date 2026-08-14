# IAM resources for workload-specific permissions
# will be added as individual services require them.

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
  role       = "GitHubActionsCloudCommerceDeploy"
  policy_arn = aws_iam_policy.github_actions_ecr.arn
}

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
  role       = "GitHubActionsCloudCommerceDeploy"
  policy_arn = aws_iam_policy.github_actions_eks.arn
}