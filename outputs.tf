# =============================================================================
# Outputs
# =============================================================================

output "ecr_repository_urls" {
  description = "ECR repository URLs for all services"
  value = {
    backend  = aws_ecr_repository.backend.repository_url
    crew     = aws_ecr_repository.crew.repository_url
    web      = aws_ecr_repository.web.repository_url
    calendar = aws_ecr_repository.calendar.repository_url
  }
}

output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_eip.app.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.app.public_dns
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = "ssh -i ${var.ssh_key_name}.pem ec2-user@${aws_eip.app.public_ip}"
}

output "app_url" {
  description = "AquaOS application URL"
  value       = "http://${aws_eip.app.public_ip}"
}

output "api_health_url" {
  description = "Health check URL"
  value       = "http://${aws_eip.app.public_ip}/api/health"
}

output "crew_health_url" {
  description = "CrewAI health check URL"
  value       = "http://${aws_eip.app.public_ip}:8001/health"
}

output "dynamodb_tables" {
  description = "DynamoDB table names"
  value = {
    series        = aws_dynamodb_table.series.name
    polling_config = aws_dynamodb_table.polling_config.name
    manual_event   = aws_dynamodb_table.manual_event.name
  }
}
