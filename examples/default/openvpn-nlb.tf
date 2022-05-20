# ------------------------------------------------------------------------------
# OpenVPN NLB Labels
# ------------------------------------------------------------------------------
module "openvpn_daemon_nlb_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.openvpn_meta.context
  attributes      = ["daemon", "nlb"]
  id_length_limit = 32
}

module "openvpn_daemon_nlb_tgt_meta" {
  count      = length(local.nlb_protocols)
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.openvpn_daemon_nlb_meta.context
  attributes = [local.nlb_protocols[count.index], "tgt"]
}

module "openvpn_ui_nlb_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.openvpn_meta.context
  attributes      = ["ui", "nlb"]
  id_length_limit = 32
}

module "openvpn_ui_nlb_tgt_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.openvpn_ui_nlb_meta.context
  attributes = ["https", "tgt"]
}

module "openvpn_ui_nlb_dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.dns_meta.context
  name    = "${module.openvpn_dns_meta.name}-ui-nlb"
}


# ------------------------------------------------------------------------------
# OpenVPN Daemon NLB
# ------------------------------------------------------------------------------
module "openvpn_daemon_nlb" {
  source  = "app.terraform.io/SevenPico/nlb/aws"
  version = "0.8.2.1"
  context = module.openvpn_daemon_nlb_meta.context

  access_logs_enabled                     = false
  access_logs_prefix                      = module.openvpn_daemon_nlb_meta.id
  access_logs_s3_bucket_id                = ""
  certificate_arn                         = module.ssl_certificate.acm_certificate_arn
  create_default_target_group             = false
  cross_zone_load_balancing_enabled       = true
  deletion_protection_enabled             = false
  deregistration_delay                    = 300
  enable_glacier_transition               = var.logs_storage_enable_glacier_transition
  expiration_days                         = var.logs_storage_expiration_days
  glacier_transition_days                 = var.logs_storage_glacier_transition_days
  health_check_enabled                    = true
  health_check_interval                   = 10
  health_check_path                       = "/"
  health_check_port                       = var.openvpn_daemon_tcp_port
  health_check_protocol                   = "TCP"
  health_check_threshold                  = 2
  internal                                = false
  ip_address_type                         = "ipv4"
  lifecycle_rule_enabled                  = false
  nlb_access_logs_s3_bucket_force_destroy = false
  noncurrent_version_expiration_days      = var.logs_storage_noncurrent_version_expiration_days
  noncurrent_version_transition_days      = var.logs_storage_noncurrent_version_expiration_days
  standard_transition_days                = var.logs_storage_standard_transition_days
  subnet_ids                              = module.vpc_subnets.public_subnet_ids
  target_group_additional_tags            = {}
  target_group_name                       = ""
  target_group_port                       = 0
  target_group_target_type                = "instance"
  tcp_enabled                             = false
  tcp_port                                = 443
  tls_enabled                             = false
  tls_port                                = 443
  tls_ssl_policy                          = "ELBSecurityPolicy-2016-08"
  udp_enabled                             = false
  udp_port                                = 1194
  vpc_id                                  = module.vpc.vpc_id
}


# ------------------------------------------------------------------------------
# OpenVPN Daemon NLB Target Groups and Listeners
# ------------------------------------------------------------------------------
locals {
  tcp_daemon_protocol = var.openvpn_daemon_tcp_port != null ? "TCP" : null
  udp_daemon_protocol = var.openvpn_daemon_udp_port != null ? "UDP" : null
  nlb_protocols       = compact([local.tcp_daemon_protocol, local.udp_daemon_protocol])
  nlb_ports           = compact([var.openvpn_daemon_tcp_port, var.openvpn_daemon_udp_port])
}

resource "aws_lb_target_group" "openvpn_daemon_nlb" {
  count                = module.openvpn_daemon_nlb_meta.enabled ? length(local.nlb_protocols) : 0
  name                 = module.openvpn_daemon_nlb_tgt_meta[count.index].id
  port                 = local.nlb_ports[count.index]
  protocol             = local.nlb_protocols[count.index]
  vpc_id               = module.vpc.vpc_id
  target_type          = "instance"
  deregistration_delay = 300
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "TCP"
    port                = var.openvpn_daemon_tcp_port
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = module.openvpn_daemon_nlb_tgt_meta[count.index].tags
}

resource "aws_lb_listener" "openvpn_daemon_nlb" {
  count             = module.openvpn_daemon_nlb_meta.enabled ? length(local.nlb_protocols) : 0
  load_balancer_arn = module.openvpn_daemon_nlb.nlb_arn
  port              = local.nlb_ports[count.index]
  protocol          = local.nlb_protocols[count.index]
  default_action {
    target_group_arn = aws_lb_target_group.openvpn_daemon_nlb[count.index].arn
    type             = "forward"
  }
}


# ------------------------------------------------------------------------------
# OpenVPN UI NLB
# ------------------------------------------------------------------------------
module "openvpn_ui_nlb" {
  source  = "app.terraform.io/SevenPico/nlb/aws"
  version = "0.8.2.1"
  context = module.openvpn_ui_nlb_meta.context

  access_logs_enabled                     = false
  access_logs_prefix                      = module.openvpn_ui_nlb_meta.id
  access_logs_s3_bucket_id                = ""
  certificate_arn                         = module.ssl_certificate.acm_certificate_arn
  create_default_target_group             = true
  cross_zone_load_balancing_enabled       = true
  deletion_protection_enabled             = false
  deregistration_delay                    = 300
  enable_glacier_transition               = var.logs_storage_enable_glacier_transition
  expiration_days                         = var.logs_storage_expiration_days
  glacier_transition_days                 = var.logs_storage_glacier_transition_days
  health_check_enabled                    = true
  health_check_interval                   = 10
  health_check_path                       = "/"
  health_check_port                       = var.openvpn_ui_https_port
  health_check_protocol                   = "HTTPS"
  health_check_threshold                  = 2
  internal                                = false
  ip_address_type                         = "ipv4"
  lifecycle_rule_enabled                  = false
  nlb_access_logs_s3_bucket_force_destroy = false
  noncurrent_version_expiration_days      = var.logs_storage_noncurrent_version_expiration_days
  noncurrent_version_transition_days      = var.logs_storage_noncurrent_version_expiration_days
  standard_transition_days                = var.logs_storage_standard_transition_days
  subnet_ids                              = module.vpc_subnets.public_subnet_ids
  target_group_additional_tags            = {}
  target_group_name                       = module.openvpn_ui_nlb_tgt_meta.id
  target_group_port                       = var.openvpn_ui_https_port
  target_group_target_type                = "instance"
  tcp_enabled                             = false
  tcp_port                                = var.openvpn_ui_alb_https_port
  tls_enabled                             = true
  tls_port                                = var.openvpn_ui_alb_https_port
  tls_ssl_policy                          = "ELBSecurityPolicy-2016-08"
  udp_enabled                             = false
  udp_port                                = 1194
  vpc_id                                  = module.vpc.vpc_id
}


## ------------------------------------------------------------------------------
## OpenVPN UI NLB Target Group and Listener
## ------------------------------------------------------------------------------
#resource "aws_lb_target_group" "openvpn_ui_nlb" {
#  count                = module.openvpn_ui_nlb_meta.enabled ? 1 : 0
#  name                 = module.openvpn_ui_nlb_tgt_meta[count.index].id
#  port                 = var.openvpn_ui_https_port
#  protocol             = "TCP"
#  vpc_id               = module.vpc.vpc_id
#  target_type          = "instance"
#  deregistration_delay = 300
#  health_check {
#    enabled             = true
#    healthy_threshold   = 2
#    unhealthy_threshold = 2
#    interval            = 10
#    protocol            = "TCP"
#    port                = var.openvpn_ui_https_port
#  }
#  lifecycle {
#    create_before_destroy = true
#  }
#  tags = module.openvpn_ui_nlb_tgt_meta[count.index].tags
#}
#
#resource "aws_lb_listener" "openvpn_ui_nlb" {
#  count             = module.openvpn_ui_nlb_meta.enabled ? 1 : 0
#  load_balancer_arn = module.openvpn_ui_nlb.nlb_arn
#  port              = var.openvpn_ui_https_port
#  protocol          = "TCP"
#  default_action {
#    target_group_arn = aws_lb_target_group.openvpn_ui_nlb[count.index].arn
#    type             = "forward"
#  }
#}


# ------------------------------------------------------------------------------
# OpenVPN NLB DNS Records
# ------------------------------------------------------------------------------
resource "aws_route53_record" "openvpn_daemon_nlb" {
  count   = module.openvpn_daemon_nlb_meta.enabled ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = module.openvpn_dns_meta.id
  type    = "A"
  alias {
    name                   = one(module.openvpn_daemon_nlb[*].nlb_dns_name)
    zone_id                = one(module.openvpn_daemon_nlb[*].nlb_zone_id)
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "openvpn_ui_nlb" {
  count   = module.openvpn_ui_nlb_meta.enabled ? 1 : 0
  name    = module.openvpn_ui_nlb_dns_meta.id
  type    = "A"
  zone_id = aws_route53_zone.public[0].id
  alias {
    name                   = module.openvpn_ui_nlb.nlb_dns_name
    zone_id                = module.openvpn_ui_nlb.nlb_zone_id
    evaluate_target_health = true
  }
}
