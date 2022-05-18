# ------------------------------------------------------------------------------
# OpenVPN ALB Labels
# ------------------------------------------------------------------------------
module "openvpn_alb_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.openvpn_meta.context
  attributes      = ["alb"]
  id_length_limit = 32
}

module "openvpn_alb_tgt_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.openvpn_alb_meta.context
  name       = null
  attributes = ["tgt"]
}


# ------------------------------------------------------------------------------
# OpenVPN ALB
# ------------------------------------------------------------------------------
module "openvpn_alb" {
  source  = "registry.terraform.io/cloudposse/alb/aws"
  version = "1.0.0"
  context = module.openvpn_alb_meta.context


  access_logs_enabled                     = false
  access_logs_prefix                      = module.openvpn_alb_meta.id
  access_logs_s3_bucket_id                = ""
  additional_certs                        = []
  alb_access_logs_s3_bucket_force_destroy = true
  certificate_arn                         = module.ssl_certificate.acm_certificate_arn
  cross_zone_load_balancing_enabled       = true
  default_target_group_enabled            = true
  deletion_protection_enabled             = false
  deregistration_delay                    = 15
  drop_invalid_header_fields              = false
  enable_glacier_transition               = var.logs_storage_enable_glacier_transition
  expiration_days                         = var.logs_storage_expiration_days
  glacier_transition_days                 = var.logs_storage_glacier_transition_days
  health_check_healthy_threshold          = 2
  health_check_interval                   = 15
  health_check_matcher                    = "200-399"
  health_check_path                       = "/"
  health_check_port                       = var.openvpn_ui_https_port
  health_check_timeout                    = 10
  health_check_unhealthy_threshold        = 2
  http2_enabled                           = true
  http_enabled                            = false
  http_ingress_cidr_blocks                = ["0.0.0.0/0"]
  http_ingress_prefix_list_ids            = []
  http_port                               = 80
  http_redirect                           = true
  https_enabled                           = true
  https_ingress_cidr_blocks               = ["0.0.0.0/0"]
  https_ingress_prefix_list_ids           = []
  https_port                              = var.openvpn_ui_alb_https_port
  https_ssl_policy                        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  idle_timeout                            = 60
  internal                                = false
  ip_address_type                         = "ipv4"
  lifecycle_rule_enabled                  = false
  listener_http_fixed_response            = null
  listener_https_fixed_response           = null
  load_balancer_name                      = ""
  load_balancer_name_max_length           = 32
  noncurrent_version_expiration_days      = var.logs_storage_noncurrent_version_expiration_days
  noncurrent_version_transition_days      = var.logs_storage_noncurrent_version_transition_days
  security_group_enabled                  = true
  security_group_ids                      = []
  standard_transition_days                = var.logs_storage_standard_transition_days
  stickiness = {
    cookie_duration = 600
    enabled         = true
  }
  subnet_ids                   = module.vpc_subnets.public_subnet_ids
  target_group_additional_tags = {}
  target_group_name            = module.openvpn_alb_tgt_meta.id
  target_group_name_max_length = 32
  target_group_port            = var.openvpn_ui_https_port
  target_group_protocol        = "HTTPS"
  target_group_target_type     = "instance"
  vpc_id                       = module.vpc.vpc_id
}


# ------------------------------------------------------------------------------
# OpenVPN ALB DNS Record
# ------------------------------------------------------------------------------
module "openvpn_alb_dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.dns_meta.context
  name    = "${module.openvpn_dns_meta.name}-ui"
}

resource "aws_route53_record" "openvpn_alb" {
  count   = module.openvpn_alb_dns_meta.enabled ? 1 : 0
  name    = module.openvpn_alb_dns_meta.id
  type    = "A"
  zone_id = aws_route53_zone.public[0].id
  alias {
    name                   = module.openvpn_alb.alb_dns_name
    zone_id                = module.openvpn_alb.alb_zone_id
    evaluate_target_health = true
  }
}

