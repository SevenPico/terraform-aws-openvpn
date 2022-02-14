module "openvpn" {
  source  = "../.."
  context = module.this.context

  # Required
  openvpn_asg_ami_image_id          = "ami-06e31403ada2e8ff4"
  openvpn_public_hosted_zone_id     = data.aws_route53_zone.public.id
  openvpn_server_dhcp_option_domain = aws_route53_zone.private.name
  openvpn_vpc_cidr_block            = module.vpc.vpc_cidr_block
  openvpn_vpc_id                    = module.vpc.vpc_id
  openvpn_vpc_private_subnet_ids    = module.vpc_subnets.private_subnet_ids
  openvpn_vpc_public_subnet_ids     = module.vpc_subnets.public_subnet_ids

  # Optional
  openvpn_asg_unique_instance_hostnames = var.openvpn_asg_unique_instance_hostnames
  openvpn_cloudwatch_log_retention_days = var.openvpn_cloudwatch_log_retention_days
  openvpn_desired_count                 = var.openvpn_desired_count
  openvpn_instance_type                 = var.openvpn_instance_type
  openvpn_max_count                     = var.openvpn_max_count
  openvpn_min_count                     = var.openvpn_min_count
  openvpn_server_admin_ui_https_port    = var.openvpn_server_admin_ui_https_port
  openvpn_server_client_ui_https_port   = var.openvpn_server_client_ui_https_port
  openvpn_server_cluster_port           = var.openvpn_server_cluster_port
  openvpn_server_daemon_tcp_port        = var.openvpn_server_daemon_tcp_port
  openvpn_server_daemon_udp_port        = var.openvpn_server_daemon_udp_port
  openvpn_timezone                      = var.openvpn_timezone
  openvpn_web_server_name               = var.openvpn_web_server_name
  openvpn_admin_password                = var.openvpn_admin_password
  openvpn_admin_username                = var.openvpn_admin_username
  openvpn_client_network                = var.openvpn_client_network
  openvpn_client_network_mask           = var.openvpn_client_network_mask
  openvpn_license_filepath              = var.openvpn_license_filepath

  rds_mysql_instance_address                       = module.rds.instance_address
  rds_secretsmanager_version_arn                    = data.aws_secretsmanager_secret_version.rds[0].arn
  rds_secretsmanager_kms_key_arn                   = aws_kms_key.rds[0].arn
  rds_secretsmanager_secret_admin_password_keyname = var.rds_secretsmanager_secret_admin_password_keyname
  rds_secretsmanager_secret_admin_username_keyname = var.rds_secretsmanager_secret_admin_username_keyname
  rds_secretsmanager_secret_port_keyname           = var.rds_secretsmanager_secret_port_keyname

  ssl_certificate_secretsmanager_version_arn                            = module.ssl_certificate.secretsmanager_arn
  ssl_certificate_secretsmanager_kms_key_arn                            = module.ssl_certificate.kms_key_arn
  ssl_certificate_secretsmanager_secret_certificate_bundle_keyname      = var.ssl_certificate_secretsmanager_secret_certificate_bundle_keyname
  ssl_certificate_secretsmanager_secret_certificate_keyname             = var.ssl_certificate_secretsmanager_secret_certificate_keyname
  ssl_certificate_secretsmanager_secret_certificate_private_key_keyname = var.ssl_certificate_secretsmanager_secret_certificate_private_key_keyname
}
