locals {
  env = terraform.workspace
}

module "network" {
  source   = "../modules/network"
  env      = local.env
  vpc_cidr = "10.0.0.0/16"
}

module "emr" {
  source             = "../modules/emr"
  env                = local.env
  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids
}
