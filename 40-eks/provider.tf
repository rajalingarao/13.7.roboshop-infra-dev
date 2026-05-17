terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.95"# Terraform AWS provider version
    }
  }

  backend "s3" {
    bucket = "roboshop13-remote-state"
    key    = "roboshop-eks-1"
    region = "us-east-1"
    #dynamodb_table = "roboshop13-locking"
    use_lockfile = true
  }
}


provider "aws" {
  # Configuration options
  region = "us-east-1"
}