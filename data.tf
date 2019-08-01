data "aws_availability_zones" "available" {}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners = ["amazon"]

  filter {
    name = "name"
    values = ["amzn-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name = "owner-alias"
    values = ["amazon"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/userdata.tpl")
  vars = {
    user_data_vpc_cidr        = var.vpc.vpc_cidr_block
    user_data_db_database     = module.rds_pgsql_gitlab.this_db_instance_name
    user_data_db_username     = module.rds_pgsql_gitlab.this_db_instance_username
    user_data_db_password     = module.rds_pgsql_gitlab.this_db_instance_password
    user_data_db_host         = module.rds_pgsql_gitlab.this_db_instance_address
    user_data_redis_host      = module.gitlab_redis.host
    user_data_redis_password  = random_string.auth_token.result
    user_data_gitlab_password = local.gitlab_password
    user_data_gitlab_url      = "https://${var.gitlab_name}.${local.gitlab_zone_name}"
  }
}

data "aws_route53_zone" "gitlab_zone" {
  zone_id  = var.route53_zone_id
}

data "aws_elb_service_account" "this" {}

data "aws_iam_policy_document" "logs" {
  statement {
    actions = [
      "s3:PutObject",
    ]

    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.this.arn]
    }

    resources = [
      "arn:aws:s3:::${var.name}-${random_string.this.result}-elb-logs/*",
    ]
  }
}
