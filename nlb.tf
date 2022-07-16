# ------------------------------------------------------------------------------
# NLB Labels
# ------------------------------------------------------------------------------
module "nlb_meta" {
  source          = "registry.terraform.io/cloudposse/label/null"
  version         = "0.25.0"
  context         = module.this.context
  enabled         = module.this.enabled && var.create_nlb
  attributes      = ["nlb"]
  id_length_limit = 32
}

module "nlb_tgt_meta" {
  count      = length(local.nlb_listener_protocols)
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.nlb_meta.context
  attributes = [local.nlb_listener_ports[count.index], "tgt"]
}

locals {
  nlb_listener_protocols = ["TLS", "TCP", "UDP"]
  nlb_listener_ports     = [var.openvpn_ui_https_port, var.openvpn_daemon_tcp_port, var.openvpn_daemon_udp_port]
  nlb_target_protocols   = ["TLS", "TCP", "UDP"]
  nlb_target_ports       = [var.openvpn_ui_https_port, var.openvpn_daemon_tcp_port, var.openvpn_daemon_udp_port]
  nlb_target_type        = ["instance", "instance", "instance"]

  openvpn_nlb_target_groups = [for x in aws_lb_target_group.nlb[*] :
    {
      elb_name : null
      target_group_arn : x.arn
      container_name : module.ec2_autoscale_group_meta.id
      container_port : x.port
    }
  ]
}


# ------------------------------------------------------------------------------
# NLB
# ------------------------------------------------------------------------------
module "nlb" {
  source  = "app.terraform.io/SevenPico/nlb/aws"
  version = "0.8.2.1"
  context = module.nlb_meta.context

  access_logs_enabled               = var.nlb_access_logs_s3_bucket_id != null
  access_logs_prefix                = var.nlb_access_logs_prefix_override == null ? module.nlb_meta.id : var.nlb_access_logs_prefix_override
  access_logs_s3_bucket_id          = var.nlb_access_logs_s3_bucket_id
  certificate_arn                   = var.nlb_acm_certificate_arn
  create_default_target_group       = false
  cross_zone_load_balancing_enabled = false
  deletion_protection_enabled       = var.nlb_deletion_protection_enabled
  deregistration_delay              = 300
  health_check_enabled              = var.openvpn_ui_https_port != null
  health_check_interval             = 10
  health_check_path                 = "/"
  health_check_port                 = var.openvpn_ui_https_port
  health_check_protocol             = "HTTPS"
  health_check_threshold            = 2
  internal                          = false
  ip_address_type                   = "ipv4"
  subnet_ids                        = var.nlb_subnet_ids
  target_group_additional_tags      = {}
  target_group_name                 = ""
  target_group_port                 = 0
  target_group_target_type          = "ip"
  tcp_enabled                       = false
  tcp_port                          = var.openvpn_daemon_tcp_port
  tls_enabled                       = false
  tls_port                          = var.openvpn_ui_https_port
  tls_ssl_policy                    = var.nlb_tls_ssl_policy
  udp_enabled                       = false
  udp_port                          = var.openvpn_daemon_udp_port
  vpc_id                            = var.vpc_id
}


# ------------------------------------------------------------------------------
# NLB Target Groups and Listeners
# ------------------------------------------------------------------------------
resource "aws_lb_target_group" "nlb" {
  count                = module.nlb_meta.enabled ? length(local.nlb_target_protocols) : 0
  name                 = module.nlb_tgt_meta[count.index].id
  port                 = local.nlb_target_ports[count.index]
  protocol             = local.nlb_target_protocols[count.index]
  vpc_id               = var.vpc_id
  target_type          = local.nlb_target_type[count.index]
  deregistration_delay = 300
  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 10
    protocol            = "HTTPS"
    port                = var.openvpn_ui_https_port
    path                = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = module.nlb_tgt_meta[count.index].tags
}

resource "aws_lb_listener" "nlb" {
  count             = module.nlb_meta.enabled ? length(local.nlb_listener_protocols) : 0
  load_balancer_arn = module.nlb.nlb_arn
  port              = local.nlb_listener_ports[count.index]
  protocol          = local.nlb_listener_protocols[count.index]
  certificate_arn   = local.nlb_listener_protocols[count.index] == "TLS" ? var.nlb_acm_certificate_arn : null
  default_action {
    target_group_arn = aws_lb_target_group.nlb[count.index].arn
    type             = "forward"
  }
}