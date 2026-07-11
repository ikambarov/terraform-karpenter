output "database_address" {
  description = "RDS MySQL writer endpoint hostname."
  value       = aws_db_instance.client_tracker.address
}

output "database_port" {
  description = "RDS MySQL port."
  value       = aws_db_instance.client_tracker.port
}

output "database_name" {
  description = "Client Tracker database name."
  value       = var.database_name
}

output "database_username" {
  description = "Client Tracker database username."
  value       = var.database_username
}

output "database_secret_arn" {
  description = "AWS-managed Secrets Manager secret ARN for the RDS master user."
  value       = aws_db_instance.client_tracker.master_user_secret[0].secret_arn
}
