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
  availability_zone = ""
  openvpn_dhcp_option_domain = module.context.domain_name
  openvpn_hostname           = module.openvpn_context.dns_name
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id

  # Create Options
create_ec2_autoscale_sns_topic = false
create_nlb = false
create_openvpn_secret = false

   # Enablements
enable_efs = false
enable_nat = true
enable_custom_ssl = true
enable_licensing = false
enable_openvpn_backups = true
enable_ec2_cloudwatch_logs = true

  # Logging
cloudwatch_logs_expiration_days = 90

# SSL
ssl_secret_arn = module.ssl_certificate.secret_arn
ssl_secret_kms_key_arn = module.ssl_certificate.kms_key_arn
ssl_secret_certificate_bundle_keyname =
ssl_secret_certificate_keyname
ssl_secret_certificate_private_key_keyname

//# EC2
//ec2_associate_public_ip_address
//ec2_ami_id
//ec2_autoscale_desired_count
//ec2_autoscale_instance_type
//ec2_autoscale_max_count
//ec2_autoscale_min_count
//ec2_autoscale_sns_topic_default_result
//ec2_autoscale_sns_topic_heartbeat_timeout
//ec2_additional_security_group_ids
//ec2_initialization_schedule_expression
//ec2_upgrade_schedule_expression
//ec2_security_group_allow_all_egress
//ec2_security_group_rules
//ec2_additional_instance_role_policies
//
//# NLB
//nlb_access_logs_prefix_override = var.nlb_access_logs_s3_bucket_id
//nlb_access_logs_s3_bucket_id    = var.nlb_access_logs_prefix_override
//nlb_acm_certificate_arn         = module.ssl_certificate.acm_certificate_arn
//nlb_deletion_protection_enabled = false
//nlb_subnet_ids                  = module.vpc_subnets.public_subnet_ids
//nlb_tls_ssl_policy              = "ELBSecurityPolicy-TLS13-1-2-2021-06"
//
//# S3
//s3_source_policy_document
//
//# OpenVPN
//openvpn_backup_schedule_expression
//openvpn_client_cidr_blocks
//openvpn_client_dhcp_network
//openvpn_client_dhcp_network_mask
//openvpn_client_static_addresses_enabled
//openvpn_client_static_network
//openvpn_client_static_network_mask
//openvpn_daemon_ingress_blocks
//openvpn_daemon_tcp_port
//openvpn_daemon_udp_port
//openvpn_enable_mfa_delete
//openvpn_s3_access_logs_prefix_override
//openvpn_s3_access_logs_s3_bucket_id
//openvpn_s3_force_destroy
//openvpn_s3_lifecycle_configuration_rules
//openvpn_s3_versioning_enabled
//openvpn_secret_admin_password_key
//openvpn_secret_arn
//openvpn_secret_enable_kms_key_rotation
//openvpn_secret_kms_key_arn
//openvpn_time_zone
//openvpn_ui_https_port
//openvpn_ui_ingress_blocks
//openvpn_web_server_name
//openvpn_s3_object_ownership
//openvpn_tls_version_min
//openvpn_enable_server_nat
//openvpn_version


//
//  # Required
//
//
//  # Optional
//  create_ec2_autoscale_sns_topic = false
//  create_nlb                     = true
//  create_openvpn_secret          = true
//
//  enable_ec2_cloudwatch_logs              = true
//  cloudwatch_logs_expiration_days = 90
//
//  # EC2 Inputs
//  ec2_additional_instance_role_policies     = []
//  ec2_additional_security_group_ids         = []
//  ec2_ami_id                                = "ami-0574da719dca65348"
//  ec2_associate_public_ip_address           = true
//  ec2_autoscale_desired_count               = 1
//  ec2_autoscale_instance_type               = "t3.micro"
//  ec2_autoscale_max_count                   = 1
//  ec2_autoscale_min_count                   = 1
//  ec2_autoscale_sns_topic_default_result    = "CONTINUE"
//  ec2_autoscale_sns_topic_heartbeat_timeout = 180
//  enable_openvpn_backups                        = true
//  openvpn_backup_schedule_expression            = "cron(0 00 00 ? * * *)"
//  ec2_initialization_schedule_expression    = null
//  ec2_key_name                              = null
//  ec2_preserve_security_group_id            = true
//  ec2_user_data                             = ""
//  enable_efs                               = false
//  ec2_security_group_allow_all_egress       = false
//  ec2_security_group_rules = [
//    {
//      key                      = "egress-to-vpc-443"
//      type                     = "egress"
//      from_port                = 443
//      to_port                  = 443
//      protocol                 = "tcp"
//      cidr_blocks              = [module.vpc.vpc_cidr_block]
//      ipv6_cidr_blocks         = []
//      source_security_group_id = null
//      self                     = null
//      description              = "Allow https egress to VPC."
//    },
//    {
//      key                      = "egress-to-cloudflare"
//      type                     = "egress"
//      from_port                = 443
//      to_port                  = 443
//      protocol                 = "tcp"
//      cidr_blocks              = local.cloudflare_cidrs
//      ipv6_cidr_blocks         = []
//      source_security_group_id = null
//      self                     = null
//      description              = "Allow https egress to Cloudflare."
//    }
//  ]
//
//
//  # OpenVPN Inputs
//  openvpn_client_cidr_blocks              = ["172.27.0.0/16"]
//  openvpn_client_dhcp_network             = "172.27.32.0"
//  openvpn_client_dhcp_network_mask        = "20"
//  openvpn_client_static_addresses_enabled = false
//  openvpn_client_static_network           = "172.27.64.0"
//  openvpn_client_static_network_mask      = "20"
//  openvpn_config_scripts_additional = [
//    local.nat_routing_script_name,
//    local.ssl_script_name
//  ]
//  openvpn_daemon_ingress_blocks              = ["0.0.0.0/0"]
//  openvpn_daemon_tcp_port                    = null
//  openvpn_daemon_udp_port                    = 1194
//  openvpn_enable_mfa_delete                  = false
//  openvpn_enable_server_nat                  = true
//  openvpn_s3_access_logs_prefix_override     = null
//  openvpn_s3_access_logs_s3_bucket_id        = null
//  openvpn_s3_force_destroy                   = true
//  openvpn_s3_lifecycle_configuration_rules   = var.openvpn_s3_lifecycle_configuration_rules
//  openvpn_s3_object_ownership                = "BucketOwnerEnforced"
//  openvpn_s3_source_policy_documents         = []
//  openvpn_s3_versioning_enabled              = true
//  openvpn_secret_admin_password_key          = "ADMIN_PASSWORD"
//  openvpn_secret_arn                         = ""
//  openvpn_secret_enable_kms_key_rotation     = true
//  openvpn_secret_kms_key_arn                 = null
//  openvpn_ssm_association_output_bucket_name = null
//  openvpn_time_zone                          = "America/Chicago"
//  openvpn_tls_version_min                    = "1.2"
//  openvpn_ui_https_port                      = 443
//  openvpn_ui_ingress_blocks                  = ["0.0.0.0/0"]
//  openvpn_version                            = "2.11.1-f4027f58-Ubuntu22"
//  openvpn_web_server_name                    = "OpenVPN Server"
}

#------------------------------------------------------------------------------
# OpenVPN Configuration Scripts
#------------------------------------------------------------------------------
locals {
  nat_routing_script_name = "nat-routing.sh"
  ssl_script_name         = "ssl-config.sh"
}
//
//module "openvpn_nat_routing_script" {
//  source  = "../../modules/reverse-routing-script"
//  context = module.openvpn_context.self
//
//  bucket_id                  = module.openvpn.ssm_script_bucket_id
//  script_name                = local.nat_routing_script_name
//  ec2_role_name              = module.openvpn.role_name
//  openvpn_client_cidr_blocks = ["172.27.0.0/16"]
//  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
//}
//
//module "openvpn_ssl_config_script" {
//  source     = "../../modules/ssl-config-script"
//  context    = module.openvpn_context.self
//  depends_on = [module.openvpn]
//
//  bucket_id              = module.openvpn.ssm_script_bucket_id
//  ec2_role_name          = module.openvpn.role_name
//  script_name            = local.ssl_script_name
//  ssl_secret_arn         = module.ssl_certificate.secret_arn
//  ssl_secret_kms_key_arn = module.ssl_certificate.kms_key_arn
//}

# Delays VPN initialization until all resources are in place
resource "null_resource" "openvpn_set_autoscale_counts" {
  count      = module.openvpn_context.enabled ? 1 : 0
  depends_on = [module.openvpn]

  provisioner "local-exec" {
    command = join(" ", [
      "aws", "autoscaling", "update-auto-scaling-group",
      "--auto-scaling-group-name", module.openvpn.autoscale_group_name,
      "--desired-capacity", 1
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
