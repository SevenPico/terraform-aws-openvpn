
data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_route53_zone" "public" {
  zone_id = var.openvpn_public_hosted_zone_id
}
