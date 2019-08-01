locals {
  gitlab_zone_name = substr(data.aws_route53_zone.gitlab_zone.name, 0, length(data.aws_route53_zone.gitlab_zone.name)-1)

  db_password     = random_id.random_16[0].b64_url
  gitlab_password = random_id.random_16[1].b64_url


}
