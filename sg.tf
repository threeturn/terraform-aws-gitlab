
module "gitlab_ssh_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "ssh-from-bastion"
  description = "Security group for bastion host with SSH ports open within VPC"
  vpc_id      = var.vpc.vpc_id
  version     = "3.0.1"

  create = length(var.bastion_sg_id) > 0 ? true : false

  ingress_with_source_security_group_id = [
    {
      rule                     = "ssh-tcp"
      source_security_group_id = var.bastion_sg_id
    }
  ]
}

module "all_egress_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "all_egress"
  description = "Security group for egress"
  vpc_id      = var.vpc.vpc_id

  egress_rules = ["all-all"]
  egress_cidr_blocks = ["0.0.0.0/0"]
}


module "gitlab_elb_https_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "https-from-trusted-ip"
  description = "Security group for gitlab with https ports open within VPC"
  vpc_id      = var.vpc.vpc_id
  version     = "3.0.1"

  ingress_rules = ["https-443-tcp", "http-80-tcp"]
  ingress_cidr_blocks = var.https_trusted_ip

  egress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.gitlab_ec2_http_sg.this_security_group_id
    }
  ]

}


module "gitlab_ec2_http_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "https-for-gitlab-ASG"
  description = "Security group for gitlab ec2 instance with http ports open within VPC"
  vpc_id      = var.vpc.vpc_id
  version     = "3.0.1"

  ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.gitlab_elb_https_sg.this_security_group_id
    }
  ]
}

module "gitlab_pgsql_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "pgsql-for-gitlab-ASG"
  description = "Security group for RDS postgresql with pgsql ports open within VPC"
  vpc_id      = var.vpc.vpc_id
  version     = "3.0.1"

  ingress_with_source_security_group_id = [
    {
      rule                     = "postgresql-tcp"
      source_security_group_id = module.gitlab_ec2_http_sg.this_security_group_id
    }
  ]
}
