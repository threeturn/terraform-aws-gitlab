
resource "aws_s3_bucket" "gitlab_elb_logs" {
  bucket        = "${var.name}-${random_string.this.result}-elb-logs"
  acl           = "private"
  policy        = data.aws_iam_policy_document.logs.json
  force_destroy = true
}

