resource "aws_cloudwatch_metric_alarm" "cloudfront_5xx" {
  alarm_name          = "cloud-commerce-prod-cloudfront-5xx"
  alarm_description   = "CloudFront is returning elevated 5xx responses"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 5
  period              = 300
  statistic           = "Average"
  namespace           = "AWS/CloudFront"
  metric_name         = "5xxErrorRate"

  dimensions = {
    DistributionId = aws_cloudfront_distribution.rovestore.id
    Region         = "Global"
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "cloud-commerce-prod-cloudfront-5xx"
    Project     = "cloud-commerce"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "cloud-commerce-prod-waf-blocked-requests"
  alarm_description   = "CloudFront WAF is blocking elevated request volume"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 100
  period              = 300
  statistic           = "Sum"
  namespace           = "AWS/WAFV2"
  metric_name         = "BlockedRequests"

  dimensions = {
    WebACL = "roveshop-cloudfront-waf"
    Region = "Global"
    Rule   = "ALL"
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "cloud-commerce-prod-waf-blocked-requests"
    Project     = "cloud-commerce"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}