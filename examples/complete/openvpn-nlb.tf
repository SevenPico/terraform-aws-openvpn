# ------------------------------------------------------------------------------
# OpenVPN NLB Labels
# ------------------------------------------------------------------------------
module "openvpn_nlb_context" {
  source          = "app.terraform.io/SevenPico/context/null"
  version         = "1.0.2"
  context         = module.openvpn_context.self
  attributes      = ["nlb"]
  id_length_limit = 32
}

module "openvpn_nlb_tgt_context" {
  count      = length(local.nlb_listener_protocols)
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.openvpn_nlb_context.self
  attributes = [local.nlb_listener_ports[count.index], "tgt"]
}

locals {
  nlb_listener_protocols = ["TLS", "TCP", "UDP"]
  nlb_listener_ports     = [943, 443, 1194]
  nlb_target_protocols   = ["TLS", "TCP", "UDP"]
  nlb_target_ports       = [943, 443, 1194]
  nlb_target_type        = ["instance", "instance", "instance"]

  openvpn_nlb_target_groups = [for x in aws_lb_target_group.openvpn_nlb[*] :
    {
      elb_name : null
      target_group_arn : x.arn
      container_name : module.openvpn_context.id
      container_port : x.port
    }
  ]
}


# ------------------------------------------------------------------------------
# OpenVPN NLB
# ------------------------------------------------------------------------------
module "openvpn_nlb" {
  source  = "app.terraform.io/SevenPico/nlb/aws"
  version = "0.8.2.1"
  context = module.openvpn_nlb_context.self

  access_logs_enabled                     = false
  access_logs_prefix                      = module.openvpn_nlb_context.id
  access_logs_s3_bucket_id                = module.openvpn_nlb_context.id
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
  health_check_port                       = 943
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
  target_group_name                       = ""
  target_group_port                       = 0
  target_group_target_type                = "ip"
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
# OpenVPN NLB Target Groups and Listeners
# ------------------------------------------------------------------------------
resource "aws_lb_target_group" "openvpn_nlb" {
  count                = module.openvpn_nlb_context.enabled ? length(local.nlb_target_protocols) : 0
  name                 = module.openvpn_nlb_tgt_context[count.index].id
  port                 = local.nlb_target_ports[count.index]
  protocol             = local.nlb_target_protocols[count.index]
  vpc_id               = module.vpc.vpc_id
  target_type          = local.nlb_target_type[count.index]
  deregistration_delay = 300
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTPS"
    port                = 943
    path                = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = module.openvpn_nlb_tgt_context[count.index].tags
}

resource "aws_lb_listener" "openvpn_nlb" {
  count             = module.openvpn_nlb_context.enabled ? length(local.nlb_listener_protocols) : 0
  load_balancer_arn = module.openvpn_nlb.nlb_arn
  port              = local.nlb_listener_ports[count.index]
  protocol          = local.nlb_listener_protocols[count.index]
  certificate_arn   = local.nlb_listener_protocols[count.index] == "TLS" ? module.ssl_certificate.acm_certificate_arn : null
  default_action {
    target_group_arn = aws_lb_target_group.openvpn_nlb[count.index].arn
    type             = "forward"
  }
}


# ------------------------------------------------------------------------------
# OpenVPN NLB DNS Records
# ------------------------------------------------------------------------------
resource "aws_route53_record" "openvpn_nlb" {
  count    = module.openvpn_nlb_context.enabled ? 1 : 0
  zone_id  = aws_route53_zone.public[0].id
  name     = module.openvpn_dns_context.id
  type     = "A"
  alias {
    name                   = one(module.openvpn_nlb[*].nlb_dns_name)
    zone_id                = one(module.openvpn_nlb[*].nlb_zone_id)
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "openvpn_nlb_private_zone" {
  count   = module.openvpn_nlb_context.enabled ? 1 : 0
  zone_id = aws_route53_zone.private[0].id
  name    = module.openvpn_dns_context.id
  type    = "A"
  alias {
    name                   = one(module.openvpn_nlb[*].nlb_dns_name)
    zone_id                = one(module.openvpn_nlb[*].nlb_zone_id)
    evaluate_target_health = true
  }
}
