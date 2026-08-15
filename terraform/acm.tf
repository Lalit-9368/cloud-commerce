
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

resource "aws_acm_certificate" "rovestore" {
  provider = aws.us_east_1

  domain_name = "roveshop.in"

  subject_alternative_names = [
    "www.roveshop.in"
  ]

  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "roveshop-in"
    Environment = "production"
    Phase       = "phase-3"
  }
}