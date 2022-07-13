#------------------------------------------------------------------------------
# OpenVPN Labels
#------------------------------------------------------------------------------
module "openvpn_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
}

module "openvpn_dns_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.dns_meta.context
  attributes = "vpn"
}


#------------------------------------------------------------------------------
# OpenVPN
#------------------------------------------------------------------------------
module "openvpn" {
  source  = "../.."
  context = module.this.context

  # Required
  subnet_ids                 = module.vpc_subnets.private_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id
  openvpn_dhcp_option_domain = var.common_name
  openvpn_hostname           = "vpn"

  # Optional
  ec2_ami_id                                = var.ami_id
  ec2_associate_public_ip_address           = false
  ec2_autoscale_desired_count               = var.autoscale_desired_count
  ec2_autoscale_instance_type               = var.autoscale_instance_type
  ec2_autoscale_max_count                   = var.autoscale_max_count
  ec2_autoscale_min_count                   = var.autoscale_min_count
  ec2_autoscale_sns_topic_default_result    = var.autoscale_sns_topic_default_result
  ec2_autoscale_sns_topic_heartbeat_timeout = var.autoscale_sns_topic_heartbeat_timeout

  cloudwatch_logs_expiration_days = var.cloudwatch_logs_expiration_days
  create_ec2_autoscale_sns_topic  = var.create_autoscale_sns_topic
  ec2_user_data                   = var.ec2_user_data
  openvpn_client_cidr_blocks      = var.openvpn_client_cidr_blocks
  openvpn_daemon_ingress_blocks   = var.openvpn_daemon_ingress_blocks
  openvpn_nlb_target_groups       = aws_lb_target_group.openvpn_nlb.*.arn
  openvpn_daemon_tcp_port         = var.openvpn_daemon_tcp_port
  openvpn_daemon_udp_port         = var.openvpn_daemon_udp_port
  openvpn_time_zone               = var.openvpn_time_zone

  openvpn_ui_https_port     = var.openvpn_ui_https_port
  openvpn_ui_ingress_blocks = var.openvpn_ui_ingress_blocks
  openvpn_web_server_name   = var.openvpn_web_server_name

  openvpn_config_scripts_additional = [
    "init.sh",
    "openvpn.sh",
    local.network_script_name,
    local.mysql_script_name,
    local.ssl_script_name,
    local.license_script_name,
  ]

  openvpn_secret_arn                = one(aws_secretsmanager_secret.openvpn[*].arn)
  openvpn_secret_kms_key_arn        = module.openvpn_secret_kms_key.key_arn
  openvpn_secret_admin_password_key = "ADMIN_PASSWORD"

  logs_storage_bucket_id                              = var.logs_storage_bucket_id
  logs_storage_abort_incomplete_multipart_upload_days = var.logs_storage_abort_incomplete_multipart_upload_days
  logs_storage_enable_glacier_transition              = var.logs_storage_enable_glacier_transition
  logs_storage_enable_noncurrent_version_expiration   = var.logs_storage_enable_noncurrent_version_expiration
  logs_storage_expiration_days                        = var.logs_storage_expiration_days
  logs_storage_force_destroy                          = var.logs_storage_force_destroy
  logs_storage_glacier_transition_days                = var.logs_storage_glacier_transition_days
  logs_storage_lifecycle_rule_enabled                 = var.logs_storage_lifecycle_rule_enabled
  logs_storage_noncurrent_version_expiration_days     = var.logs_storage_noncurrent_version_expiration_days
  logs_storage_noncurrent_version_transition_days     = var.logs_storage_noncurrent_version_transition_days
  logs_storage_standard_transition_days               = var.logs_storage_standard_transition_days
  logs_storage_versioning_enabled                     = var.logs_storage_versioning_enabled
  logs_storage_versioning_mfa_delete_enabled          = var.logs_storage_versioning_mfa_delete_enabled
}

# Delays VPN initialization until all resources are in place
resource "null_resource" "openvpn_set_autoscale_counts" {
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




