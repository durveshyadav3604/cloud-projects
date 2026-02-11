terraform {
  backend "s3" {
    bucket       = "github-terraform-bucket-durvesh-27"
    key          = "prod/rds/terraform.tfstate"
    region       = "ap-south-1"
    use_lockfile = true
    #dynamodb_table = "vegeta-terraform-remote-state-table"
  }
}
