terraform {
  required_version = ">= 0.12.0"
}

provider "aws" {
  version = ">= 2.11"
  region  = var.region
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "template" {
  version = "~> 2.1"
}

data "aws_availability_zones" "available" {}

resource "aws_key_pair" "example-ssh-gitlab" {
  key_name   = "example-ssh-gitlab"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAxjlXgMiuCUSyfDaVQOmnefLj+v21udxkf207YWiuxHONYoNKt+r3SpzKfjF1Tu/PvonuPsouuQQRnWA5Zc3Rl971I2cHuZCe1WIQCGQK2fm88aovQr1P44RoG9MZ4KM8ibjs8YwK/XKTJftb3fsz8VeFZaIm9qC42YjyjdOlZOwhDR4nnsYvHEFDVC1MYeeZ0mK0nrMxptGX3+ii1RdjS2GpF2a86+fWRGxM1fl08cLQgNg2Zht+DPzsVnH9GOAZaW5jXcln+j0H2ekXX6nU+U6eEperx8TsIvyduonM2FGqCd4oYHOnkncN4J0wjH8ZlJXo0Sc7+J2BOdCgjiSSuQ=="
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.6.0"

  name                 = "test-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets       = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  database_subnets     = ["10.0.7.0/24", "10.0.8.0/24", "10.0.9.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
}

module "gitlab" {
  source = "../"
  namespace        = var.namespace
  stage            = var.stage
  ssh_keypair      = aws_key_pair.example-ssh-gitlab.key_name
  gitlab_name      = var.gitlab_name
  vpc              = module.vpc
  route53_zone_id  = var.tld_zone_id

  tags      = {}
  #bastion_sg_id = module.ssh_sg.this_security_group_id
}