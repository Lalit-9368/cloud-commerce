resource "aws_acm_certificate" "origin" {
  provider = aws.us_east_1

  domain_name       = "origin.roveshop.in"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "roveshop-origin"
    Environment = "production"
    Project     = "cloud-commerce"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route53_record" "origin_acm_validation" {
  for_each = {
    for dvo in aws_acm_certificate.origin.domain_validation_options :
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

resource "aws_acm_certificate_validation" "origin" {
  provider = aws.us_east_1

  certificate_arn = aws_acm_certificate.origin.arn

  validation_record_fqdns = [
    for record in aws_route53_record.origin_acm_validation :
    record.fqdn
  ]
}
