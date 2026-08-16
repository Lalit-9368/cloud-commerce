data "aws_lb" "frontend_monitoring" {
  name = "k8s-cloudcom-frontend-a5bd147b35"
}

resource "aws_cloudwatch_metric_alarm" "alb_unhealthy_hosts" {
  alarm_name          = "cloud-commerce-prod-alb-unhealthy-hosts"
  alarm_description   = "ALB has one or more unhealthy targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  threshold           = 0
  period              = 60
  statistic           = "Average"
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"

  dimensions = {
    LoadBalancer = data.aws_lb.frontend_monitoring.arn_suffix
    TargetGroup  = "targetgroup/k8s-cloudcom-frontend-2d85d034b7/ff8a6116b1e91097"
  }

  treat_missing_data = "notBreaching"

  tags = {
    Name        = "cloud-commerce-prod-alb-unhealthy-hosts"
    Project     = "cloud-commerce"
    Environment = "prod"
    ManagedBy   = "Terraform"
  }
}

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
