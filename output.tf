

output "db_config" {
  value = {
    user     = module.rds_pgsql_gitlab.this_db_instance_username
    password = module.rds_pgsql_gitlab.this_db_instance_password
    database = module.rds_pgsql_gitlab.this_db_instance_name
    hostname = module.rds_pgsql_gitlab.this_db_instance_address
    port     = module.rds_pgsql_gitlab.this_db_instance_port
  }
}

output "redis_config" {
  value = {
    id         = module.gitlab_redis.id
    auth_token = random_string.auth_token.result
    hostname   = module.gitlab_redis.host
    port       = module.gitlab_redis.port
  }
}

output "asg_name" {
  value = module.gitlab_asg.this_launch_configuration_name
}

output "gitlab_root_password" {
  value = local.gitlab_password
}

output "gitlab_url" {
  value = "https://${var.gitlab_name}.${local.gitlab_zone_name}"
}
