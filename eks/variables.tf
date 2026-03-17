# Empty for now; EKS module variables handled in modules/eks
variable "env" {
  type = string
  description = "Environment (dev/prod)"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
