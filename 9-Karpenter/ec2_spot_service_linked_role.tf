# Account-level prerequisite for launching EC2 Spot capacity.
resource "aws_iam_service_linked_role" "ec2_spot" {
  aws_service_name = "spot.amazonaws.com"
}

