
resource "aws_route53_zone" "rovestore" {
  name = "roveshop.in"

  tags = {
    Name        = "roveshop.in"
    Environment = "production"
    Phase       = "phase-3"
  }
}

# ACM DNS validation records
resource "aws_route53_record" "acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.rovestore.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = aws_route53_zone.rovestore.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60

  records = [
    each.value.record
  ]

  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "rovestore" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.rovestore.arn

  validation_record_fqdns = [
    for record in aws_route53_record.acm_validation :
    record.fqdn
  ]
}
resource "aws_route53_record" "origin" {
  zone_id = aws_route53_zone.rovestore.zone_id
  name    = "origin.roveshop.in"
  type    = "A"

  alias {
    name                   = "dualstack.k8s-cloudcom-frontend-a5bd147b35-1153733148.us-east-1.elb.amazonaws.com"
    zone_id                = "Z35SXDOTRQ7X7K"
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "root" {
  zone_id = aws_route53_zone.rovestore.zone_id
  name    = "roveshop.in"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.rovestore.domain_name
    zone_id                = aws_cloudfront_distribution.rovestore.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.rovestore.zone_id
  name    = "www.roveshop.in"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.rovestore.domain_name
    zone_id                = aws_cloudfront_distribution.rovestore.hosted_zone_id
    evaluate_target_health = false
  }
}