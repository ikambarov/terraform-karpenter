# AWS Account Info
data "aws_caller_identity" "aws_account" {}

data "aws_iam_policy_document" "node_controller_policy_doc" {

  # EC2 launch permissions for region-scoped infrastructure assets
  statement {
    sid     = "Ec2LaunchBaseResources"
    effect  = "Allow"
    actions = ["ec2:RunInstances", "ec2:CreateFleet"]

    resources = [
      "arn:aws:ec2:${var.aws_region}::image/*",
      "arn:aws:ec2:${var.aws_region}::snapshot/*",
      "arn:aws:ec2:${var.aws_region}:*:security-group/*",
      "arn:aws:ec2:${var.aws_region}:*:subnet/*",
      "arn:aws:ec2:${var.aws_region}:*:capacity-reservation/*",
    ]
  }

  # Launch template usage restricted to cluster-owned resources
  statement {
    sid     = "Ec2LaunchTemplateScoped"
    effect  = "Allow"
    actions = ["ec2:RunInstances", "ec2:CreateFleet"]

    resources = [
      "arn:aws:ec2:${var.aws_region}:*:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  # EC2 resource creation requiring cluster and node pool tags
  statement {
    sid     = "Ec2CreateWithRequestTags"
    effect  = "Allow"
    actions = ["ec2:RunInstances", "ec2:CreateFleet", "ec2:CreateLaunchTemplate"]

    resources = [
      "arn:aws:ec2:${var.aws_region}:*:instance/*",
      "arn:aws:ec2:${var.aws_region}:*:fleet/*",
      "arn:aws:ec2:${var.aws_region}:*:volume/*",
      "arn:aws:ec2:${var.aws_region}:*:network-interface/*",
      "arn:aws:ec2:${var.aws_region}:*:launch-template/*",
      "arn:aws:ec2:${var.aws_region}:*:spot-instances-request/*",
      "arn:aws:ec2:${var.aws_region}:*:capacity-reservation/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.eks_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [var.eks_cluster_name]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  # Tagging permissions during EC2 create operations
  statement {
    sid     = "Ec2TagOnCreate"
    effect  = "Allow"
    actions = ["ec2:CreateTags"]

    resources = [
      "arn:aws:ec2:${var.aws_region}:*:instance/*",
      "arn:aws:ec2:${var.aws_region}:*:fleet/*",
      "arn:aws:ec2:${var.aws_region}:*:volume/*",
      "arn:aws:ec2:${var.aws_region}:*:network-interface/*",
      "arn:aws:ec2:${var.aws_region}:*:launch-template/*",
      "arn:aws:ec2:${var.aws_region}:*:spot-instances-request/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values   = ["RunInstances", "CreateFleet", "CreateLaunchTemplate"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.eks_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/eks:eks-cluster-name"
      values   = [var.eks_cluster_name]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  # Controlled tagging of existing EC2 instances
  statement {
    sid     = "Ec2InstanceTagUpdate"
    effect  = "Allow"
    actions = ["ec2:CreateTags"]

    resources = [
      "arn:aws:ec2:${var.aws_region}:*:instance/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values   = ["eks:eks-cluster-name", "karpenter.sh/nodeclaim", "Name"]
    }
  }

  # Instance and launch template deletion limited by ownership tags
  statement {
    sid     = "Ec2ScopedDeletion"
    effect  = "Allow"
    actions = ["ec2:TerminateInstances", "ec2:DeleteLaunchTemplate"]

    resources = [
      "arn:aws:ec2:${var.aws_region}:*:instance/*",
      "arn:aws:ec2:${var.aws_region}:*:launch-template/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.eks_cluster_name}"
      values   = ["owned"]
    }
  }

  # Read-only EC2 queries restricted to the active region
  statement {
    sid    = "Ec2RegionalRead"
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeCapacityReservations",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # Access to AWS-managed SSM public parameters
  statement {
    sid     = "SsmPublicParameterRead"
    effect  = "Allow"
    actions = ["ssm:GetParameter"]

    resources = [
      "arn:aws:ssm:${var.aws_region}::parameter/aws/service/*",
    ]
  }

  # Pricing API access for instance cost evaluation
  statement {
    sid       = "PricingReadOnly"
    effect    = "Allow"
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }

  # SQS permissions for interruption handling
  statement {
    sid    = "InterruptionQueueAccess"
    effect = "Allow"
    actions = [
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
    ]

    resources = [aws_sqs_queue.karpenter_node_interruption_queue.arn]
  }

  # Permission to pass the node instance role to EC2
  statement {
    sid     = "IamPassNodeRole"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = [aws_iam_role.karpenter_node_instance_role.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com", "ec2.amazonaws.com.cn"]
    }
  }

  # Instance profile creation requires Karpenter ownership tags
  statement {
    sid    = "InstanceProfileCreateTagged"
    effect = "Allow"
    actions = [
      "iam:CreateInstanceProfile",
      "iam:TagInstanceProfile",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.aws_account.account_id}:instance-profile/${var.eks_cluster_name}_*",
      "arn:aws:iam::${data.aws_caller_identity.aws_account.account_id}:instance-profile/karpenter/${var.aws_region}/${var.eks_cluster_name}/*",
    ]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass"
      values   = ["*"]
    }
  }

  # Instance profile lifecycle actions do not carry request tags, so scope by cluster-prefixed profile names
  statement {
    sid    = "InstanceProfileLifecycle"
    effect = "Allow"
    actions = [
      "iam:AddRoleToInstanceProfile",
      "iam:RemoveRoleFromInstanceProfile",
      "iam:DeleteInstanceProfile",
      "iam:GetInstanceProfile",
    ]

    resources = [
      "arn:aws:iam::${data.aws_caller_identity.aws_account.account_id}:instance-profile/${var.eks_cluster_name}_*",
      "arn:aws:iam::${data.aws_caller_identity.aws_account.account_id}:instance-profile/karpenter/${var.aws_region}/${var.eks_cluster_name}/*",
    ]
  }

  # List operation required for instance profile discovery
  statement {
    sid       = "InstanceProfileList"
    effect    = "Allow"
    actions   = ["iam:ListInstanceProfiles"]
    resources = ["*"]
  }

  # EKS cluster metadata lookup for endpoint discovery
  statement {
    sid     = "EksClusterDescribe"
    effect  = "Allow"
    actions = ["eks:DescribeCluster"]

    resources = [
      "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.aws_account.account_id}:cluster/${var.eks_cluster_name}",
    ]
  }
}

resource "aws_iam_policy" "karpenter_node_controller_policy" {
  name        = "${var.environment_name}-karpenter-node-controller-policy"
  description = "IAM policy for Kubernetes node provisioning controller"
  policy      = data.aws_iam_policy_document.node_controller_policy_doc.json
  tags        = var.common_tags
}

resource "aws_iam_role_policy_attachment" "karpenter_node_controller_policy_attach" {
  role       = aws_iam_role.karpenter_node_provisioner_role.name
  policy_arn = aws_iam_policy.karpenter_node_controller_policy.arn
}
