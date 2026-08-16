resource "aws_cloudfront_distribution" "rovestore" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "RoveShop production CDN"
  default_root_object = "index.html"
  web_acl_id          = aws_wafv2_web_acl.roveshop.arn

  aliases = [
    "roveshop.in",
    "www.roveshop.in"
  ]

  origin {
    domain_name = "origin.roveshop.in"
    origin_id   = "roveshop-alb"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  origin {
    domain_name              = aws_s3_bucket.roveshop_fallback.bucket_regional_domain_name
    origin_id                = "roveshop-s3-fallback"
    origin_access_control_id = aws_cloudfront_origin_access_control.roveshop_fallback.id
  }

  origin_group {
    origin_id = "roveshop-origin-failover"

    failover_criteria {
      status_codes = [
        500,
        502,
        503,
        504
      ]
    }

    member {
      origin_id = "roveshop-alb"
    }

    member {
      origin_id = "roveshop-s3-fallback"
    }
  }

  default_cache_behavior {
    target_origin_id       = "roveshop-origin-failover"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    cached_methods = [
      "GET",
      "HEAD",
      "OPTIONS"
    ]

    compress = true

    forwarded_values {
      query_string = true

      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.rovestore.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  price_class = "PriceClass_100"

  tags = {
    Name        = "roveshop-cloudfront"
    Project     = "cloud-commerce"
    Environment = "prod"
    ManagedBy   = "Terraform"
    Phase       = "phase-8"
  }
}
