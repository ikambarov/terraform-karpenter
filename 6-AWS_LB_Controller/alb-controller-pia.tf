# Associate IAM role with EKS service account for ALB Controller
resource "aws_eks_pod_identity_association" "alb_controller" {
  cluster_name    = data.aws_eks_cluster.target.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.alb_controller_role.arn
}

# Output ALB Controller Pod Identity Association ARN
output "alb_controller_pod_identity_association_arn" {
  description = "ARN of the ALB Controller EKS Pod Identity Association"
  value       = aws_eks_pod_identity_association.alb_controller.association_arn
}