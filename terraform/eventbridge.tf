# ============================================================
# EventBridge - Application Events
# ============================================================

resource "aws_cloudwatch_event_bus" "application" {
  name = "${var.project_name}-${var.environment}-events"

  tags = {
    Name        = "${var.project_name}-${var.environment}-events"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_cloudwatch_event_rule" "application_events" {
  name           = "${var.project_name}-${var.environment}-events"
  description    = "Routes Cloud Commerce application events to SQS"
  event_bus_name = aws_cloudwatch_event_bus.application.name

  event_pattern = jsonencode({
    source = [
      "cloud-commerce"
    ]
  })
}

resource "aws_cloudwatch_event_target" "sqs" {
  rule           = aws_cloudwatch_event_rule.application_events.name
  event_bus_name = aws_cloudwatch_event_bus.application.name
  target_id      = "cloud-commerce-events-queue"
  arn            = aws_sqs_queue.events.arn
}

resource "aws_sqs_queue_policy" "events" {
  queue_url = aws_sqs_queue.events.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "AllowEventBridgeSendMessage"
        Effect = "Allow"

        Principal = {
          Service = "events.amazonaws.com"
        }

        Action = "sqs:SendMessage"

        Resource = aws_sqs_queue.events.arn

        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_cloudwatch_event_rule.application_events.arn
          }
        }
      }
    ]
  })
}
