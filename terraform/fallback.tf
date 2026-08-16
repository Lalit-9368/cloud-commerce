data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "roveshop_fallback" {
  bucket = "cloud-commerce-roveshop-fallback-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "roveshop-fallback"
    Project     = "cloud-commerce"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Phase       = "phase-8"
  }
}

resource "aws_s3_bucket_public_access_block" "roveshop_fallback" {
  bucket = aws_s3_bucket.roveshop_fallback.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "roveshop_fallback" {
  bucket = aws_s3_bucket.roveshop_fallback.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "roveshop_fallback" {
  bucket = aws_s3_bucket.roveshop_fallback.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_cloudfront_origin_access_control" "roveshop_fallback" {
  name                              = "roveshop-fallback-oac"
  description                       = "CloudFront access to RoveShop fallback bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_s3_object" "roveshop_fallback" {
  bucket       = aws_s3_bucket.roveshop_fallback.id
  key          = "index.html"
  content_type = "text/html"

  content = <<-HTML
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>RoveShop</title>
</head>
<body>
  <h1>RoveShop</h1>
  <p>The application is temporarily unavailable. Please try again shortly.</p>
</body>
</html>
HTML
}

resource "aws_s3_bucket_policy" "roveshop_fallback" {
  bucket = aws_s3_bucket.roveshop_fallback.id

  depends_on = [
    aws_s3_bucket_public_access_block.roveshop_fallback,
    aws_cloudfront_origin_access_control.roveshop_fallback
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowCloudFrontRead"
        Effect = "Allow"

        Principal = {
          Service = "cloudfront.amazonaws.com"
        }

        Action = [
          "s3:GetObject"
        ]

        Resource = "${aws_s3_bucket.roveshop_fallback.arn}/*"

        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.rovestore.arn
          }
        }
      }
    ]
  })
}
