terraform {
  backend "s3" {
    bucket         = "ppd-terraform-state"
    key            = "data-platform/eks/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "ppd-terraform-locks"
  }
}
