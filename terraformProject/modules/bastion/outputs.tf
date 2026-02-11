output "bastion_id" {
  value       = aws_instance.bastion.id
  description = "ID of the bastion host"
}