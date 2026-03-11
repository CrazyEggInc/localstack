terraform {
  required_version = "1.14.7"

  backend "s3" {
    bucket = "crazyegg-terraform-remote-state"
    dynamodb_table = "crazyegg-terraform-remote-state-lock"
    key = "localstack.tfstate"
    region = "us-east-1"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = local.workspace["region"]
}
