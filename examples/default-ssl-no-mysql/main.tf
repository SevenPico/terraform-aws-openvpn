module "openvpn" {
  source  = "../.."
  context = module.this.context

  # Required
  openvpn_dhcp_option_domain = var.openvpn_dhcp_option_domain
  private_hosted_zone_id     = var.private_hosted_zone_id
  private_subnet_ids         = var.private_subnet_ids
  public_hosted_zone_id      = var.public_hosted_zone_id
  public_subnet_ids          = var.public_subnet_ids
  vpc_cidr_blocks            = var.vpc_cidr_blocks
  vpc_id                     = var.vpc_id

  # Optional
  ami_id                          = var.ami_id
  autoscale_desired_count         = var.autoscale_desired_count
  autoscale_instance_type         = var.autoscale_instance_type
  autoscale_max_count             = var.autoscale_max_count
  autoscale_min_count             = var.autoscale_min_count
  cloudwatch_logs_expiration_days = var.cloudwatch_logs_expiration_days
  create_autoscale_sns_topic      = var.create_autoscale_sns_topic
  security_group_id               = var.security_group_id
  openvpn_cluster_port            = var.openvpn_cluster_port
  openvpn_daemon_tcp_port         = var.openvpn_daemon_tcp_port
  openvpn_daemon_udp_port         = var.openvpn_daemon_udp_port
  openvpn_license_filepath        = var.openvpn_license_filepath
  openvpn_ui_https_port           = var.openvpn_ui_https_port
  openvpn_timezone                = var.openvpn_timezone
  openvpn_web_server_name         = var.openvpn_web_server_name

  openvpn_client_cidr_blocks           = var.openvpn_client_cidr_blocks
  openvpn_client_dhcp_network          = var.openvpn_client_dhcp_network
  openvpn_client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask
  openvpn_client_group_dhcp_cidr_block = var.openvpn_client_group_dhcp_cidr_block
  openvpn_client_static_network        = var.openvpn_client_static_network
  openvpn_client_static_network_mask   = var.openvpn_client_static_network_mask

  #  load_balancer_acm_arn = var.load_balancer_acm_arn
  #  load_balancer_enabled = true

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

  rds_mysql_instance_address        = var.rds_mysql_instance_address
  rds_secret_admin_password_keyname = var.rds_secret_admin_password_keyname
  rds_secret_admin_username_keyname = var.rds_secret_admin_username_keyname
  rds_secret_arn                    = var.rds_secret_arn
  rds_secret_kms_key_arn            = var.rds_secret_kms_key_arn
  rds_secret_port_keyname           = var.rds_secret_port_keyname
  rds_security_group_id             = var.rds_security_group_id

  ssl_secret_arn                             = var.ssl_secret_arn
  ssl_secret_certificate_bundle_keyname      = var.ssl_secret_certificate_bundle_keyname
  ssl_secret_certificate_keyname             = var.ssl_secret_certificate_keyname
  ssl_secret_certificate_private_key_keyname = var.ssl_secret_certificate_private_key_keyname
  ssl_secret_kms_key_arn                     = var.ssl_secret_kms_key_arn
}
