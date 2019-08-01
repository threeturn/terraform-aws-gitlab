resource "random_string" "this" {
  length  = 5
  special = false
  upper   = false
}

resource "random_string" "auth_token" {
  length = 64
  special = false
}

resource "random_id" "random_16" {
  byte_length = 16 * 3 / 4
  count       = 2
}
