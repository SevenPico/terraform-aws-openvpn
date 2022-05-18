# ------------------------------------------------------------------------------
# OpenVPN NLB Labels
# ------------------------------------------------------------------------------
module "openvpn_nlb_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.openvpn_meta.context
  attributes      = ["nlb"]
  id_length_limit = 32
}


# ------------------------------------------------------------------------------
# OpenVPN NLB
# ------------------------------------------------------------------------------
module "openvpn_nlb" {
  source  = "app.terraform.io/SevenPico/nlb/aws"
  version = "0.8.2.1"
  context = module.openvpn_nlb_meta.context

  cross_zone_load_balancing_enabled = true

  access_logs_enabled                     = false
  access_logs_prefix                      = module.openvpn_nlb_meta.id
  access_logs_s3_bucket_id                = ""
  certificate_arn                         = module.ssl_certificate.acm_certificate_arn
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
  create_default_target_group             = false
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
  udp_port                                = var.openvpn_daemon_udp_port
  vpc_id                                  = module.vpc.vpc_id
}


# ------------------------------------------------------------------------------
# OpenVPN NLB Target Groups and Listeners
# ------------------------------------------------------------------------------
locals {
  tcp_daemon_protocol = var.openvpn_daemon_tcp_port != null ? "TCP" : null
  udp_daemon_protocol = var.openvpn_daemon_udp_port != null ? "UDP" : null
  nlb_protocols       = compact([local.tcp_daemon_protocol, local.udp_daemon_protocol])
  nlb_ports           = compact([var.openvpn_daemon_tcp_port, var.openvpn_daemon_udp_port])
}

module "openvpn_nlb_tgt_meta" {
  count      = length(local.nlb_protocols)
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.openvpn_nlb_meta.context
  attributes = [local.nlb_protocols[count.index], "tgt"]
}

resource "aws_lb_target_group" "openvpn_nlb" {
  count                = module.openvpn_nlb_meta.enabled ? length(local.nlb_protocols) : 0
  name                 = module.openvpn_nlb_tgt_meta[count.index].id
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
  tags = module.openvpn_nlb_tgt_meta[count.index].tags
}

resource "aws_lb_listener" "openvpn_nlb" {
  count             = module.openvpn_nlb_meta.enabled ? length(local.nlb_protocols) : 0
  load_balancer_arn = module.openvpn_nlb.nlb_arn
  port              = local.nlb_ports[count.index]
  protocol          = local.nlb_protocols[count.index]
  default_action {
    target_group_arn = aws_lb_target_group.openvpn_nlb[count.index].arn
    type             = "forward"
  }
}


# ------------------------------------------------------------------------------
# OpenVPN NLB DNS Record
# ------------------------------------------------------------------------------
resource "aws_route53_record" "openvpn_nlb" {
  count   = module.openvpn_nlb_meta.enabled ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = module.openvpn_dns_meta.id
  type    = "A"
  alias {
    name                   = one(module.openvpn_nlb[*].nlb_dns_name)
    zone_id                = one(module.openvpn_nlb[*].nlb_zone_id)
    evaluate_target_health = true
  }
}


