# IAM trust policy for EKS pod-based role assumption
data "aws_iam_policy_document" "eks_pod_trust_policy" {
  statement {
    sid     = "EksPodAssumeRole"
    actions = ["sts:AssumeRole", "sts:TagSession"]

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

# IAM role used by the node provisioning controller
resource "aws_iam_role" "karpenter_node_provisioner_role" {
  name = "${var.environment_name}-karpenter-node-provisioner"

  assume_role_policy = data.aws_iam_policy_document.eks_pod_trust_policy.json
  tags               = var.common_tags
}

# Export IAM role name
output "node_provisioner_role_name" {
  description = "Name of the IAM role used by the node provisioning controller"
  value       = aws_iam_role.karpenter_node_provisioner_role.name
}

# Export IAM role ARN
output "node_provisioner_role_arn" {
  description = "ARN of the IAM role used by the node provisioning controller"
  value       = aws_iam_role.karpenter_node_provisioner_role.arn
}
