terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "ppd-terraform-state"
    key            = "global/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ppd-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = "us-east-1"
}
