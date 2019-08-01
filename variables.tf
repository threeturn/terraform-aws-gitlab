variable "namespace" {
  type = string
}

variable "stage" {
  type = string
}

variable "ssh_keypair" {
  type    = string
  default = ""
}

variable "vpc" {
  type = any
}

variable "db_name_instance" {
  type    = any
  default = "gitlabhq_production"
}

variable "db_username" {
  type    = any
  default = "gitlab"
}

variable "name" {
  type    = any
  default = "gitlab"
}

variable "tags" {
  type = any
}

variable "bastion_sg_id" {
  type     = string
  default  = ""
}

variable "instance_type" {
  type = "string"
  description = "instance type for gitlab"
  default = "t3.medium"
}

variable "pgsql_instance_type" {
  type = "string"
  description = "instance type for pgsql"
  default = "db.t2.micro"
}

variable "https_trusted_ip" {
  type    = list
  default = ["0.0.0.0/0"]
}

variable "gitlab_name" {
  type    = string
  default = "gitlab"
}

variable "route53_zone_id" {
  type    = string
}






