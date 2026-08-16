# ============================================================
# SQS - Application Events
# ============================================================

resource "aws_sqs_queue" "events_dlq" {
  name = "${var.project_name}-${var.environment}-events-dlq"

  sqs_managed_sse_enabled = true

  message_retention_seconds = 1209600

  tags = {
    Name        = "${var.project_name}-${var.environment}-events-dlq"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "aws_sqs_queue" "events" {
  name = "${var.project_name}-${var.environment}-events"

  sqs_managed_sse_enabled = true

  visibility_timeout_seconds = 60
  message_retention_seconds  = 345600
  receive_wait_time_seconds  = 10

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.events_dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-events"
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}
