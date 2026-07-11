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

output "database_password" {
  description = "Generated Client Tracker database password."
  value       = random_password.database.result
  sensitive   = true
}

output "database_secret_arn" {
  description = "AWS Secrets Manager secret ARN for database connection details."
  value       = aws_secretsmanager_secret.database.arn
}
