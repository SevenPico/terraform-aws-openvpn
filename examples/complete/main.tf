module "openvpn" {
  source  = "../.."
  context = module.this.context

  # Required
  subnet_ids                 = module.vpc_subnets.public_subnet_ids
  vpc_cidr_blocks            = [module.vpc.vpc_cidr_block]
  vpc_id                     = module.vpc.vpc_id
  openvpn_dhcp_option_domain = var.common_name

  # Optional
  ami_id                           = var.ami_id
  autoscale_desired_count          = var.autoscale_desired_count
  autoscale_instance_type          = var.autoscale_instance_type
  autoscale_max_count              = var.autoscale_max_count
  autoscale_min_count              = var.autoscale_min_count
  cloudwatch_logs_expiration_days  = var.cloudwatch_logs_expiration_days
  create_autoscale_sns_topic       = var.create_autoscale_sns_topic
  openvpn_daemon_ingress_blocks    = var.openvpn_daemon_ingress_blocks
  openvpn_daemon_nlb_target_groups = var.openvpn_daemon_nlb_target_groups
  openvpn_groups                   = var.openvpn_groups
  openvpn_hostname                 = "vpn"
  openvpn_ui_alb_https_port        = var.openvpn_ui_alb_https_port
  openvpn_ui_alb_security_group_id = module.alb.security_group_id
  openvpn_ui_alb_target_groups     = [module.alb.default_target_group_arn]
  openvpn_ui_ingress_blocks        = var.openvpn_ui_ingress_blocks
  openvpn_users                    = var.openvpn_users
  openvpn_config_scripts = [
    "init.sh",
    "openvpn-init.sh",
    module.mysql_config_script.script_name,
    module.ssh_config_script.script_name
  ]

  openvpn_cluster_port     = var.openvpn_cluster_port
  openvpn_daemon_tcp_port  = var.openvpn_daemon_tcp_port
  openvpn_daemon_udp_port  = var.openvpn_daemon_udp_port
  openvpn_license_filepath = var.openvpn_license_filepath
  openvpn_timezone         = var.openvpn_timezone
  openvpn_ui_https_port    = var.openvpn_ui_https_port
  openvpn_web_server_name  = var.openvpn_web_server_name

  openvpn_client_cidr_blocks           = var.openvpn_client_cidr_blocks
  openvpn_client_dhcp_network          = var.openvpn_client_dhcp_network
  openvpn_client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask
  openvpn_client_group_dhcp_cidr_block = var.openvpn_client_group_dhcp_cidr_block
  openvpn_client_static_network        = var.openvpn_client_static_network
  openvpn_client_static_network_mask   = var.openvpn_client_static_network_mask

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




