# SQS queue used for Karpenter interruption handling
resource "aws_sqs_queue" "karpenter_node_interruption_queue" {
  name                      = "${var.environment_name}-karpenter-interruptions"
  message_retention_seconds = 300
  sqs_managed_sse_enabled   = true
  tags                      = var.common_tags
}

# Queue policy allowing AWS services and enforcing TLS
resource "aws_sqs_queue_policy" "karpenter_node_interruption_queue_policy" {
  queue_url = aws_sqs_queue.karpenter_node_interruption_queue.url

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "sqs:SendMessage"
        Resource = aws_sqs_queue.karpenter_node_interruption_queue.arn
        Principal = {
          Service = [
            "events.amazonaws.com",
            "sqs.amazonaws.com"
          ]
        }
      },
      {
        Sid       = "EnforceSecureTransport"
        Effect    = "Deny"
        Action    = "sqs:*"
        Resource  = aws_sqs_queue.karpenter_node_interruption_queue.arn
        Principal = "*"
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
