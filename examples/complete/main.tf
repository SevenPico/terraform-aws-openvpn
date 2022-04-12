#module "openvpn_sg_meta" {
#  source  = "registry.terraform.io/cloudposse/label/null"
#  version = "0.25.0"
#  context = module.this.context
#  name    = "sg"
#}
#
#module "openvpn_sg" {
#  source  = "registry.terraform.io/cloudposse/security-group/aws"
#  version = "0.4.2"
#  context = module.openvpn_sg_meta.context
#  enabled = var.openvpn_security_group_id == null
#
#  vpc_id = module.vpc.vpc_id
#
#  rules = [
#    {
#      key                      = 1
#      type                     = "ingress"
#      from_port                = var.openvpn_server_admin_ui_https_port
#      to_port                  = var.openvpn_server_admin_ui_https_port
#      protocol                 = "tcp"
#      cidr_blocks              = ["0.0.0.0/0"]
#      ipv6_cidr_blocks         = []
#      source_security_group_id = null
#      self                     = null
#      description              = "Allow access to VPN Admin UI from anywhere"
#    },
#    {
#      key                      = 2
#      type                     = "ingress"
#      from_port                = var.openvpn_server_daemon_udp_port
#      to_port                  = var.openvpn_server_daemon_udp_port
#      protocol                 = "udp"
#      cidr_blocks              = ["0.0.0.0/0"]
#      ipv6_cidr_blocks         = []
#      source_security_group_id = null
#      self                     = null
#      description              = "Allow access to VPN from anywhere"
#    },
#    {
#      key                      = 3
#      type                     = "ingress"
#      from_port                = var.openvpn_server_daemon_tcp_port
#      to_port                  = var.openvpn_server_daemon_tcp_port
#      protocol                 = "tcp"
#      cidr_blocks              = ["0.0.0.0/0"]
#      ipv6_cidr_blocks         = []
#      source_security_group_id = null
#      self                     = null
#      description              = "Allow access to VPN from anywhere"
#    },
#    {
#      key                      = 4
#      type                     = "egress"
#      from_port                = 443
#      to_port                  = 443
#      protocol                 = "tcp"
#      cidr_blocks              = ["0.0.0.0/0"]
#      ipv6_cidr_blocks         = []
#      source_security_group_id = null
#      self                     = null
#      description              = "Allow https egress on 443 everywhere"
#    },
#    {
#      key                      = 5
#      type                     = "egress"
#      from_port                = 80
#      to_port                  = 80
#      protocol                 = "tcp"
#      cidr_blocks              = ["0.0.0.0/0"]
#      ipv6_cidr_blocks         = []
#      source_security_group_id = null
#      self                     = null
#      description              = "Allow https egress on 80 everywhere"
#    }
#  ]
#}

module "autoscaled_ec2_openvpn" {
  source  = "../.."
  context = module.this.context

  # Required
  openvpn_public_hosted_zone_id     = data.aws_route53_zone.public[0].id
  openvpn_server_dhcp_option_domain = aws_route53_zone.private[0].name
  openvpn_vpc_cidr_block            = module.vpc.vpc_cidr_block
  openvpn_vpc_id                    = module.vpc.vpc_id
  openvpn_vpc_private_subnet_ids    = module.vpc_subnets.private_subnet_ids
  openvpn_vpc_public_subnet_ids     = module.vpc_subnets.public_subnet_ids

  # Optional
  openvpn_asg_ami_image_id              = "ami-037ff6453f0855c46"
  openvpn_group_pool_cidr_block         = var.openvpn_group_pool_cidr_block
  openvpn_cloudwatch_log_retention_days = var.openvpn_cloudwatch_log_retention_days
  openvpn_desired_count                 = var.openvpn_desired_count
  openvpn_instance_type                 = var.openvpn_instance_type
  openvpn_max_count                     = var.openvpn_max_count
  openvpn_min_count                     = var.openvpn_min_count
  openvpn_security_group_id             = var.openvpn_security_group_id
  openvpn_server_admin_ui_https_port    = var.openvpn_server_admin_ui_https_port
  openvpn_server_client_ui_https_port   = var.openvpn_server_client_ui_https_port
  openvpn_server_cluster_port           = var.openvpn_server_cluster_port
  openvpn_server_daemon_tcp_port        = var.openvpn_server_daemon_tcp_port
  openvpn_server_daemon_udp_port        = var.openvpn_server_daemon_udp_port
  openvpn_timezone                      = var.openvpn_timezone
  openvpn_web_server_name               = var.openvpn_web_server_name
  openvpn_admin_password                = var.openvpn_admin_password
  openvpn_admin_username                = var.openvpn_admin_username
  openvpn_client_pool_network           = var.openvpn_client_pool_network
  openvpn_client_pool_network_mask      = var.openvpn_client_pool_network_mask
  openvpn_license_filepath              = var.openvpn_license_filepath

  rds_mysql_instance_address                       = module.rds.instance_address
  rds_secretsmanager_version_arn                   = data.aws_secretsmanager_secret_version.rds[0].arn
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
