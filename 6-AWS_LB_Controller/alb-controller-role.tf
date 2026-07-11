# Fetch IAM policy for AWS Load Balancer Controller
data "http" "alb_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"

  # Ensure response is JSON
  request_headers = {
    Accept = "application/json"
  }
}

# Resource: Create IAM policy for ALB Controller
resource "aws_iam_policy" "alb_controller_policy" {
  name        = "${var.environment_name}-eks-addon-alb-controller-policy"
  path        = "/"
  description = "IAM policy for AWS ALB Controller"
  policy      = data.http.alb_controller_policy.response_body
}

# Output the ARN of the IAM policy
output "alb_controller_policy_arn" {
  value = aws_iam_policy.alb_controller_policy.arn
}

# Fetch IAM Policy Document 
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

# Resource: Create IAM role for ALB Controller
resource "aws_iam_role" "alb_controller_role" {
  name               = "${var.environment_name}-eks-addon-alb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  # Tags applied to IAM role
  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment_name}-alb-controller-role"
    }
  )
}

# Attach the IAM policy to the IAM role
resource "aws_iam_role_policy_attachment" "alb_controller_role_attach" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}

# Output the ARN of the IAM role
output "alb_controller_role_arn" {
  description = "ARN of the ALB Controller IAM role"
  value       = aws_iam_role.alb_controller_role.arn
}