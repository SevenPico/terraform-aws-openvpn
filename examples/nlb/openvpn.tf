#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
}

module "openvpn_dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.dns_meta.context
  name    = "vpn"
}


#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "openvpn" {
  source     = "../.."
  context    = module.openvpn_meta.context
  depends_on = [module.ssl_certificate]

  # Required
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id
  openvpn_dhcp_option_domain = var.common_name
  openvpn_hostname           = module.openvpn_dns_meta.id

  #Optional
  create_ec2_autoscale_sns_topic             = false
  create_nlb                                 = true
  create_openvpn_secret                      = true
  cloudwatch_logs_expiration_days            = 90
  ec2_user_data                              = ""
  ec2_associate_public_ip_address            = true
  ec2_ami_id                                 = "ami-037ff6453f0855c46"
  ec2_autoscale_desired_count                = 0
  ec2_autoscale_instance_type                = "t3.micro"
  ec2_autoscale_max_count                    = 1
  ec2_autoscale_min_count                    = 0
  ec2_autoscale_sns_topic_default_result     = "CONTINUE"
  ec2_autoscale_sns_topic_heartbeat_timeout  = 180
  ec2_additional_security_group_ids          = []
  ec2_key_name                               = null
  nlb_access_logs_prefix_override            = null
  nlb_access_logs_s3_bucket_id               = null
  nlb_acm_certificate_arn                    = module.ssl_certificate.acm_certificate_arn
  nlb_deletion_protection_enabled            = false
  nlb_subnet_ids                             = module.vpc_subnets.public_subnet_ids
  nlb_tls_ssl_policy                         = "ELBSecurityPolicy-TLS13-1-1-2021-06"
  openvpn_client_cidr_blocks                 = ["172.27.0.0/16"]
  openvpn_client_dhcp_network                = "172.27.32.0"
  openvpn_client_dhcp_network_mask           = "20"
  openvpn_client_static_addresses_enabled    = false
  openvpn_client_static_network              = "172.27.64.0"
  openvpn_client_static_network_mask         = "20"
  openvpn_config_scripts_additional          = ["reverse-routing.sh", "ssl.sh"]
  openvpn_daemon_ingress_blocks              = ["0.0.0.0/0"]
  openvpn_daemon_tcp_port                    = 443
  openvpn_daemon_udp_port                    = 1194
  openvpn_s3_access_logs_prefix_override     = null
  openvpn_s3_access_logs_s3_bucket_id        = null
  openvpn_s3_force_destroy                   = true
  openvpn_s3_lifecycle_configuration_rules   = []
  openvpn_s3_versioning_enabled              = true
  openvpn_secret_admin_password_key          = "ADMIN_PASSWORD"
  openvpn_secret_arn                         = ""
  openvpn_secret_enable_kms_key_rotation     = true
  openvpn_secret_kms_key_arn                 = null
  openvpn_ssm_association_output_bucket_name = null
  openvpn_time_zone                          = "America/Chicago"
  openvpn_ui_https_port                      = 943
  openvpn_ui_ingress_blocks                  = ["0.0.0.0/0"]
  openvpn_web_server_name                    = "OpenVPN Server"
}
#locals {
#  openvpn_sg_rules = [
#    module.vpc_endpoint_sg["ec2"].id,
#    module.vpc_endpoint_sg["ec2messages"].id,
#    module.vpc_endpoint_sg["logs"].id,
#    module.vpc_endpoint_sg["s3"].id,
#    module.vpc_endpoint_sg["secretsmanager"].id,
#    module.vpc_endpoint_sg["ssm"].id,
#    module.vpc_endpoint_sg["ssmmessages"].id
#  ]
#}
#
#resource "aws_security_group_rule" "openvpn_vpc_link" {
#  count                    = module.openvpn_meta.enabled ? length(local.openvpn_sg_rules) : 0
#  from_port                = 443
#  protocol                 = "tcp"
#  security_group_id        = module.openvpn.security_group_id
#  to_port                  = 443
#  type                     = "egress"
#  source_security_group_id = local.openvpn_sg_rules[count.index]
#  description              = "Egress to VPC Private Link"
#}



# Delays VPN initialization until all resources are in place
resource "null_resource" "openvpn_set_autoscale_counts" {
  count = module.openvpn_meta.enabled ? 1 : 0
  provisioner "local-exec" {
    command = join(" ", [
      "aws", "autoscaling", "update-auto-scaling-group",
      "--auto-scaling-group-name", module.openvpn.autoscale_group_name,
      "--desired-capacity", 1,
      "--profile", "7pi.io" # FIXME - profile should be a var?
    ])
  }

  depends_on = [
    module.openvpn
  ]
}

module "reverse_routing_script" {
  source     = "../../modules/reverse-routing-script"
  context    = module.this.context
  depends_on = [module.openvpn]

  bucket_id     = module.openvpn.ssm_script_bucket_id
  script_name   = "reverse-routing.sh"
  ec2_role_name = module.openvpn.role_name
  #  openvpn_client_dhcp_network          = var.openvpn_client_dhcp_network
  #  openvpn_client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask
  #  openvpn_client_group_dhcp_cidr_block = var.openvpn_client_group_dhcp_cidr_block
  openvpn_client_cidr_blocks = var.openvpn_client_cidr_blocks
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
}

#module "static_client_addresses_script" {
#  source     = "../../modules/static-client-addresses-script"
#  context    = module.this.context
#  depends_on = [module.openvpn]
#
#  bucket_id                          = module.openvpn.ssm_script_bucket_id
#  script_name                        = "static-client-addresses.sh"
#  ec2_role_name                      = module.openvpn.role_name
#  openvpn_client_static_network      = "172.27.32.0"
#  openvpn_client_static_network_mask = "20"
#}

module "openvpn_ssl_config_script" {
  source     = "../../modules/ssl-config-script"
  context    = module.this.context
  depends_on = [module.openvpn]

  bucket_id              = module.openvpn.ssm_script_bucket_id
  script_name            = "ssl.sh"
  ec2_role_name          = module.openvpn.role_name
  ssl_secret_arn         = module.ssl_certificate.secret_arn
  ssl_secret_kms_key_arn = module.ssl_certificate.kms_key_arn
}


# ------------------------------------------------------------------------------
# OpenVPN NLB DNS Records
# ------------------------------------------------------------------------------
resource "aws_route53_record" "openvpn_nlb" {
  count   = module.openvpn_meta.enabled ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = module.openvpn_dns_meta.id
  type    = "A"
  alias {
    name                   = module.openvpn.nlb_dns_name
    zone_id                = module.openvpn.nlb_zone_id
    evaluate_target_health = true
  }
}

#resource "aws_route53_record" "openvpn_nlb_private_zone" {
#  count   = module.openvpn_meta.enabled ? 1 : 0
#  zone_id = aws_route53_zone.private[0].id
#  name    = module.openvpn_dns_meta.id
#  type    = "A"
#  alias {
#    name                   = module.openvpn.nlb_dns_name
#    zone_id                = module.openvpn.nlb_zone_id
#    evaluate_target_health = true
#  }
#}
