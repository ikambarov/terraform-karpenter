# Pod Identity trust policy for Amazon EBS CSI Driver
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole",
      "sts:TagSession"
    ]
  }
}

# Create IAM role for Amazon EBS CSI Driver
resource "aws_iam_role" "ebs_csi_role" {
  name               = "${var.environment_name}-eks-addon-ebs-csi-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.environment_name}-ebs-csi-role"
      Component = "Amazon EBS CSI Driver"
    }
  )
}

# Fetch the AWS managed IAM policy for Amazon EBS CSI Driver
data "aws_iam_policy" "ebs_csi_policy" {
  name = "AmazonEBSCSIDriverPolicy"
}

# Attach AWS Managed Policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_policy_attach" {
  role       = aws_iam_role.ebs_csi_role.name
  policy_arn = data.aws_iam_policy.ebs_csi_policy.arn
}

# Output EBS CSI IAM Role ARN
output "ebs_csi_role_arn" {
  description = "IAM Role ARN for Amazon EBS CSI Driver"
  value       = aws_iam_role.ebs_csi_role.arn
}
