# ------------------------------------------------------------------------------
# Network Load Balancer
# ------------------------------------------------------------------------------
module "nlb_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.this.context
  enabled         = module.this.context.enabled
  attributes      = ["nlb"]
  id_length_limit = 32
}

module "nlb_tgt_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.nlb_meta.context
  name       = null
  attributes = ["tgt"]
}

module "nlb" {
  source  = "app.terraform.io/SevenPico/nlb/aws"
  version = "0.8.2.1"
  context = module.nlb_meta.context

  cross_zone_load_balancing_enabled = true

  access_logs_enabled                     = false
  access_logs_prefix                      = module.nlb_meta.id
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
  create_default_target_group = false
  target_group_additional_tags            = {}
  target_group_name                       = module.nlb_tgt_meta.id
  target_group_port                       = var.openvpn_daemon_tcp_port
  target_group_target_type                = "instance"
  tcp_enabled                             = false
  tcp_port                                = var.openvpn_daemon_tcp_port
  tls_enabled                             = false
  tls_port                                = 443
  tls_ssl_policy                          = "ELBSecurityPolicy-2016-08"
  udp_enabled                             = false
  udp_port                                = var.openvpn_daemon_udp_port
  vpc_id                                  = module.vpc.vpc_id
}

locals {
  daemon_protocols = [["UDP", 1194], ["TCP", 443]]
}

resource "aws_lb_target_group" "openvpn_daemon" {
  count                = module.nlb_tgt_meta.enabled ? 1 : 0
  name                 = "${module.nlb_tgt_meta.id}-udp"
  port                 = var.openvpn_daemon_udp_port
  protocol             = "UDP"
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
  tags = module.nlb_tgt_meta.tags
}

resource "aws_lb_listener" "udp" {
  count             = module.nlb_tgt_meta.enabled ? 1 : 0
  load_balancer_arn = module.nlb.nlb_arn
  port              = var.openvpn_daemon_udp_port
  protocol          = "UDP"
  default_action {
    target_group_arn = aws_lb_target_group.udp[0].arn
    type             = "forward"
  }
}

resource "aws_lb_target_group" "tcp" {
  count                = module.nlb_tgt_meta.enabled ? 1 : 0
  name                 = "${module.nlb_tgt_meta.id}-tcp"
  port                 = var.openvpn_daemon_tcp_port
  protocol             = "TCP"
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
  tags = module.nlb_tgt_meta.tags
}

resource "aws_lb_listener" "tcp" {
  count             = module.nlb_tgt_meta.enabled ? 1 : 0
  load_balancer_arn = module.nlb.nlb_arn
  port              = var.openvpn_daemon_tcp_port
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.tcp[0].arn
    type             = "forward"
  }
}

# ------------------------------------------------------------------------------
# Network Load Balancer : DNS Record
# ------------------------------------------------------------------------------
resource "aws_route53_record" "nlb" {
  count   = module.nlb_meta.enabled ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = module.openvpn_dns_meta.id
  type    = "A"
  alias {
    name                   = one(module.nlb[*].nlb_dns_name)
    zone_id                = one(module.nlb[*].nlb_zone_id)
    evaluate_target_health = true
  }
}


