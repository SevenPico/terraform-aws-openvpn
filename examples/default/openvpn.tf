## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./examples/default/openvpn.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_context" {
  source  = "SevenPico/context/null"
  version = "2.0.0"
  context = module.context.self
  name    = "vpn"
}

locals {
  cloudflare_cidrs = [
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "108.162.192.0/18",
    "131.0.72.0/22",
    "141.101.64.0/18",
    "162.158.0.0/15",
    "172.64.0.0/13",
    "173.245.48.0/20",
    "188.114.96.0/20",
    "190.93.240.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17"
  ]
}

#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "openvpn" {
  source  = "../.."
  context = module.openvpn_context.self


  # REQUIRED
  availability_zone          = ""
  openvpn_dhcp_option_domain = module.context.domain_name
  openvpn_hostname           = module.openvpn_context.dns_name
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks = [
    module.vpc.vpc_cidr_block
  ]
  vpc_id = module.vpc.vpc_id

  # Create Options
  create_ec2_autoscale_sns_topic = false
  create_nlb                     = false
  create_openvpn_secret          = false

  # Enablements
  enable_efs                 = false
  enable_nat                 = true
  enable_custom_ssl          = true
  enable_licensing           = false
  enable_openvpn_backups     = true
  enable_ec2_cloudwatch_logs = true

  # Logging
  cloudwatch_logs_expiration_days = 90

  # SSL
  ssl_secret_arn                             = module.ssl_certificate.secret_arn
  ssl_secret_kms_key_arn                     = module.ssl_certificate.kms_key_arn
  ssl_secret_certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname
  ssl_secret_certificate_keyname             = var.ssl_secret_certificate_keyname
  ssl_secret_certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname

  # EC2
  ec2_associate_public_ip_address           = var.ec2_associate_public_ip_address
  ec2_ami_id                                = var.ec2_ami_id
  ec2_autoscale_desired_count               = var.ec2_autoscale_desired_count
  ec2_autoscale_instance_type               = var.ec2_autoscale_instance_type
  ec2_autoscale_max_count                   = var.ec2_autoscale_max_count
  ec2_autoscale_min_count                   = var.ec2_autoscale_min_count
  ec2_autoscale_sns_topic_default_result    = var.ec2_autoscale_sns_topic_default_result
  ec2_autoscale_sns_topic_heartbeat_timeout = var.ec2_autoscale_sns_topic_heartbeat_timeout
  ec2_additional_security_group_ids         = var.ec2_additional_security_group_ids
  ec2_initialization_schedule_expression    = var.ec2_initialization_schedule_expression
  ec2_upgrade_schedule_expression           = var.ec2_upgrade_schedule_expression
  ec2_security_group_allow_all_egress       = var.ec2_security_group_allow_all_egress
  ec2_security_group_rules = [
    {
      key       = "egress-to-vpc-443"
      type      = "egress"
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
      cidr_blocks = [
      module.vpc.vpc_cidr_block]
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow https egress to VPC."
    },
    {
      key                      = "egress-to-cloudflare"
      type                     = "egress"
      from_port                = 443
      to_port                  = 443
      protocol                 = "tcp"
      cidr_blocks              = local.cloudflare_cidrs
      ipv6_cidr_blocks         = []
      source_security_group_id = null
      self                     = null
      description              = "Allow https egress to Cloudflare."
    }
  ]
  ec2_additional_instance_role_policies = var.ec2_additional_instance_role_policies

  # NLB
  nlb_access_logs_prefix_override = var.nlb_access_logs_s3_bucket_id
  nlb_access_logs_s3_bucket_id    = var.nlb_access_logs_prefix_override
  nlb_acm_certificate_arn         = module.ssl_certificate.acm_certificate_arn
  nlb_deletion_protection_enabled = false
  nlb_subnet_ids                  = module.vpc_subnets.public_subnet_ids
  nlb_tls_ssl_policy              = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  # S3
  s3_source_policy_document = var.s3_source_policy_document

  # OpenVPN
  openvpn_backup_schedule_expression       = var.openvpn_backup_schedule_expression
  openvpn_client_cidr_blocks               = var.openvpn_client_cidr_blocks
  openvpn_client_dhcp_network              = var.openvpn_client_dhcp_network
  openvpn_client_dhcp_network_mask         = var.openvpn_client_dhcp_network_mask
  openvpn_client_static_addresses_enabled  = var.openvpn_client_static_addresses_enabled
  openvpn_client_static_network            = var.openvpn_client_static_network
  openvpn_client_static_network_mask       = var.openvpn_client_static_network_mask
  openvpn_daemon_ingress_blocks            = var.openvpn_daemon_ingress_blocks
  openvpn_daemon_tcp_port                  = var.openvpn_daemon_tcp_port
  openvpn_daemon_udp_port                  = var.openvpn_daemon_udp_port
  openvpn_enable_mfa_delete                = var.openvpn_enable_mfa_delete
  openvpn_s3_access_logs_prefix_override   = var.openvpn_s3_access_logs_prefix_override
  openvpn_s3_access_logs_s3_bucket_id      = var.openvpn_s3_access_logs_s3_bucket_id
  openvpn_s3_force_destroy                 = var.openvpn_s3_force_destroy
  openvpn_s3_lifecycle_configuration_rules = var.openvpn_s3_lifecycle_configuration_rules
  openvpn_s3_versioning_enabled            = var.openvpn_s3_versioning_enabled
  openvpn_secret_admin_password_key        = var.openvpn_secret_admin_password_key
  openvpn_secret_arn                       = var.openvpn_secret_arn
  openvpn_secret_enable_kms_key_rotation   = var.openvpn_secret_enable_kms_key_rotation
  openvpn_secret_kms_key_arn               = var.openvpn_secret_kms_key_arn
  openvpn_time_zone                        = var.openvpn_time_zone
  openvpn_ui_https_port                    = var.openvpn_ui_https_port
  openvpn_ui_ingress_blocks                = var.openvpn_ui_ingress_blocks
  openvpn_web_server_name                  = var.openvpn_web_server_name
  openvpn_s3_object_ownership              = var.openvpn_s3_object_ownership
  openvpn_tls_version_min                  = var.openvpn_tls_version_min
  openvpn_enable_server_nat                = var.openvpn_enable_server_nat
  openvpn_version                          = var.openvpn_version

}

#------------------------------------------------------------------------------
# OpenVPN Configuration Scripts
#------------------------------------------------------------------------------
locals {
  nat_routing_script_name = "nat-routing.sh"
  ssl_script_name         = "ssl-config.sh"
}


# Delays VPN initialization until all resources are in place
resource "null_resource" "openvpn_set_autoscale_counts" {
  count = module.openvpn_context.enabled ? 1 : 0
  depends_on = [
  module.openvpn]

  provisioner "local-exec" {
    command = join(" ", [
      "aws",
      "autoscaling",
      "update-auto-scaling-group",
      "--auto-scaling-group-name",
      module.openvpn.autoscale_group_name,
      "--desired-capacity",
      1
    ])
  }
}


# ------------------------------------------------------------------------------
# OpenVPN NLB DNS Records
# ------------------------------------------------------------------------------
resource "aws_route53_record" "openvpn_nlb" {
  count   = module.openvpn_context.enabled ? 1 : 0
  zone_id = aws_route53_zone.public[0].id
  name    = module.openvpn_context.dns_name
  type    = "A"
  alias {
    name                   = module.openvpn.nlb_dns_name
    zone_id                = module.openvpn.nlb_zone_id
    evaluate_target_health = true
  }
}
