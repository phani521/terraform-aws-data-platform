# Empty for now; EMR module variables are handled in modules/emr
# emr/variables.tf
variable "env" {
  description = "Environment name"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.env)
    error_message = "Allowed values: dev, prod."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
