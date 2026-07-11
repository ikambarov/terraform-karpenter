# Pod Identity trust policy for ExternalDNS
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

# IAM role for ExternalDNS pod identity
resource "aws_iam_role" "dns_controller_role" {
  name               = "${var.environment_name}-eks-addon-dns-controller-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Lookup AWS managed Route53 access policy
data "aws_iam_policy" "route53_access" {
  name = "AmazonRoute53FullAccess"
}

# Attach Route53 permissions to ExternalDNS role
resource "aws_iam_role_policy_attachment" "dns_controller_policy_attach" {
  role       = aws_iam_role.dns_controller_role.name
  policy_arn = data.aws_iam_policy.route53_access.arn
}

# Output ExternalDNS IAM role ARN
output "dns_controller_role_arn" {
  description = "IAM role ARN for ExternalDNS pod identity"
  value       = aws_iam_role.dns_controller_role.arn
}
