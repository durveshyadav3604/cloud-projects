variable "project_name" {}
variable "email" {}
variable "alb_arn" {}
variable "alb_target_group_arn" {}
variable "asg_name" {}
variable "scale_out_policy_arn" {
  type = string
}

variable "scale_in_policy_arn" {
  type = string
}



