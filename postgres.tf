
module "rds_pgsql_gitlab" {
  source = "terraform-aws-modules/rds/aws"

  identifier = var.name

  engine            = "postgres"
  engine_version    = "11.2"
  instance_class    = "db.t2.micro"
  allocated_storage = 5
  storage_encrypted = false

  name = var.db_name_instance
  username = var.db_username

  password = local.db_password
  port     = "5432"

  vpc_security_group_ids = [module.gitlab_pgsql_sg.this_security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 7

  tags = var.tags

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  subnet_ids = var.vpc.database_subnets

  family = "postgres11"

  major_engine_version = "11.2"

  final_snapshot_identifier = var.name

  # Database Deletion Protection
  # deletion_protection = true
}