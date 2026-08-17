locals {
  ecr_repositories = toset([
    "cloud-commerce-frontend",
    "cloud-commerce-auth-service",
    "cloud-commerce-catalog-service",
    "cloud-commerce-checkout-service",
    "cloud-commerce-payment-service",
  ])
}

resource "aws_ecr_repository" "application" {
  for_each = local.ecr_repositories

  name                 = each.value
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = each.value
    Project     = "cloud-commerce"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_ecr_lifecycle_policy" "application" {
  for_each = aws_ecr_repository.application

  repository = each.value.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep the 10 most recent images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
