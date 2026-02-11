output "asg_name" {
  value = aws_autoscaling_group.asg-tf.name
}

output "scale_out_policy_arn" {
  value = aws_autoscaling_policy.scale_out.arn
}

output "scale_in_policy_arn" {
  value = aws_autoscaling_policy.scale_in.arn
}

output "asg_sg_id" {
  description = "Security group IDs used by the ASG instances"
  value       = tolist(aws_launch_template.ec2_asg.vpc_security_group_ids)
}



output "iam_ec2_instance_profile_name" {
  description = "IAM instance profile name attached to ASG instances"
  value       = aws_launch_template.ec2_asg.iam_instance_profile[0].name
}