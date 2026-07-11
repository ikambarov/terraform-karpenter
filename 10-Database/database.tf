resource "aws_db_subnet_group" "client_tracker" {
  name       = "${var.environment_name}-client-tracker-db"
  subnet_ids = data.aws_subnets.private.ids

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment_name}-client-tracker-db"
    }
  )
}

resource "aws_security_group" "database" {
  name        = "${var.environment_name}-client-tracker-db"
  description = "Allow Client Tracker workloads to reach RDS MySQL"
  vpc_id      = data.aws_vpc.selected.id

  ingress {
    description     = "MySQL from EKS cluster security group"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.aws_eks_cluster.target.vpc_config[0].cluster_security_group_id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment_name}-client-tracker-db"
    }
  )
}

resource "aws_db_instance" "client_tracker" {
  identifier                  = "${var.environment_name}-client-tracker"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = var.instance_class
  allocated_storage           = var.allocated_storage
  db_name                     = var.database_name
  username                    = var.database_username
  manage_master_user_password = true
  db_subnet_group_name        = aws_db_subnet_group.client_tracker.name
  vpc_security_group_ids      = [aws_security_group.database.id]
  publicly_accessible         = false
  multi_az                    = false
  storage_encrypted           = true
  skip_final_snapshot         = true
  deletion_protection         = false
  apply_immediately           = true

  backup_retention_period = 1

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment_name}-client-tracker"
    }
  )
}
