
module "gitlab_redis" {
  source          = "git::https://github.com/cloudposse/terraform-aws-elasticache-redis.git?ref=master"
  namespace       = var.namespace
  name            = "gitlab_redis"
  stage           = "dev"

  security_groups = [module.gitlab_ec2_http_sg.this_security_group_id]

  auth_token                   = random_string.auth_token.result
  vpc_id                       = var.vpc.vpc_id
  subnets                      = var.vpc.database_subnets
  replication_group_id         = var.name
  maintenance_window           = "wed:03:00-wed:04:00"
  cluster_size                 = "2"
  instance_type                = "cache.t2.micro"
  engine_version               = "4.0.10"
  # alarm_cpu_threshold_percent  = "${var.cache_alarm_cpu_threshold_percent}"
  # alarm_memory_threshold_bytes = "${var.cache_alarm_memory_threshold_bytes}"
  apply_immediately            = "true"
  availability_zones           = data.aws_availability_zones.available.names

  automatic_failover = "false"
}



