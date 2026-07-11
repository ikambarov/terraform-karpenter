# Prefix
locals {
  prefix = "${var.environment_name}-eks"
}

# AWS Health events → interruption queue
resource "aws_cloudwatch_event_rule" "karpenter_health_events" {
  name        = "${local.prefix}-health"
  description = "AWS Health events forwarded to interruption queue"

  event_pattern = jsonencode({
    source        = ["aws.health"]
    "detail-type" = ["AWS Health Event"]
  })

  tags = var.common_tags
}

# Target for AWS Health events → SQS
resource "aws_cloudwatch_event_target" "karpenter_health_events_to_sqs" {
  rule      = aws_cloudwatch_event_rule.karpenter_health_events.name
  target_id = "HealthEventsTarget"
  arn       = aws_sqs_queue.karpenter_node_interruption_queue.arn
}

# EC2 Spot interruption warnings → interruption queue
resource "aws_cloudwatch_event_rule" "karpenter_spot_interruptions" {
  name        = "${local.prefix}-spot"
  description = "EC2 Spot interruption warnings forwarded to interruption queue"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Spot Instance Interruption Warning"]
  })

  tags = var.common_tags
}

# Target for Spot interruption warnings → SQS
resource "aws_cloudwatch_event_target" "karpenter_spot_interruptions_to_sqs" {
  rule      = aws_cloudwatch_event_rule.karpenter_spot_interruptions.name
  target_id = "SpotInterruptionTarget"
  arn       = aws_sqs_queue.karpenter_node_interruption_queue.arn
}

# EC2 rebalance recommendations → interruption queue
resource "aws_cloudwatch_event_rule" "karpenter_rebalance_recommendations" {
  name        = "${local.prefix}-rebalance"
  description = "EC2 rebalance recommendations forwarded to interruption queue"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance Rebalance Recommendation"]
  })

  tags = var.common_tags
}

# Target for rebalance recommendations → SQS
resource "aws_cloudwatch_event_target" "karpenter_rebalance_to_sqs" {
  rule      = aws_cloudwatch_event_rule.karpenter_rebalance_recommendations.name
  target_id = "RebalanceTarget"
  arn       = aws_sqs_queue.karpenter_node_interruption_queue.arn
}

# EC2 instance state changes → interruption queue
resource "aws_cloudwatch_event_rule" "karpenter_instance_state_changes" {
  name        = "${local.prefix}-state"
  description = "EC2 instance state changes forwarded to interruption queue"

  event_pattern = jsonencode({
    source        = ["aws.ec2"]
    "detail-type" = ["EC2 Instance State-change Notification"]
  })

  tags = var.common_tags
}

# Target for instance state changes → SQS
resource "aws_cloudwatch_event_target" "karpenter_instance_state_to_sqs" {
  rule      = aws_cloudwatch_event_rule.karpenter_instance_state_changes.name
  target_id = "InstanceStateTarget"
  arn       = aws_sqs_queue.karpenter_node_interruption_queue.arn
}
