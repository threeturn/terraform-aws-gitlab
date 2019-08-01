

#to be replaced witg ALB.

module "elb" {
  source = "terraform-aws-modules/elb/aws"
  version = "~> 2.0.0"

  name = "${var.name}-elb"

  subnets         = var.vpc.public_subnets
  security_groups = [module.gitlab_elb_https_sg.this_security_group_id]
  internal        = false

  listener = [
    {
      instance_port      = "80"
      instance_protocol  = "HTTP"
      lb_port            = "443"
      lb_protocol        = "HTTPS"
      ssl_certificate_id = module.acm.this_acm_certificate_arn
    },
    {
      instance_port      = "80"
      instance_protocol  = "HTTP"
      lb_port            = "80"
      lb_protocol        = "HTTP"
    }
  ]

  health_check = {
      target              = "HTTP:80/users/sign_in"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    }
  
  access_logs = {
    bucket = aws_s3_bucket.gitlab_elb_logs.id
  }

  tags = {
    Owner       = "user"
    Environment = "dev"
  }
}