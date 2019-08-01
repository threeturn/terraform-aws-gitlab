
module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "~> 2.2.0"

  zone_id       = var.route53_zone_id
  domain_name   = "${var.gitlab_name}.${local.gitlab_zone_name}"
  wait_for_validation = true 
}


resource "aws_route53_record" "gitlab" {
  zone_id = var.route53_zone_id
  name    = var.gitlab_name
  type    = "CNAME"
  ttl     = "300"
  records = [module.elb.this_elb_dns_name]
}

