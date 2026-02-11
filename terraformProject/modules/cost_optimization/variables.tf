variable "project_name" {}
variable "email" {}
variable "ec2_instance_types" { 
  type = list(string) 
  default = [] # Optional: default types for right-sizing suggestions
}
variable "rds_instances" {
  type = list(string)
  default = []
}
variable "s3_bucket_name" {}
variable "asg_name" {
  type = string
}

