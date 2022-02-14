# Required
variable "openvpn_asg_ami_image_id" { description = "This module was built using ami-06e31403ada2e8ff4. Other images may work as well." }
#variable "openvpn_private_hosted_zone_id" {}
variable "openvpn_public_hosted_zone_id" {}
variable "openvpn_server_dhcp_option_domain" {}
variable "openvpn_vpc_cidr_block" {}
variable "openvpn_vpc_id" {}
variable "openvpn_vpc_private_subnet_ids" {}
variable "openvpn_vpc_public_subnet_ids" {}

# Optional
variable "openvpn_admin_password" { default = "changeme" }
variable "openvpn_admin_username" { default = "administrator" }
variable "openvpn_asg_unique_instance_hostnames" { default = true }
variable "openvpn_client_network" { default = "127.27.0.0" }
variable "openvpn_client_network_mask" { default = "20" }
variable "openvpn_cloudwatch_log_retention_days" { default = 30 }
variable "openvpn_desired_count" { default = 1 }
variable "openvpn_instance_type" { default = "t3.micro" }
variable "openvpn_license_filepath" { default = null }
variable "openvpn_max_count" { default = 1 }
variable "openvpn_min_count" { default = 1 }
variable "openvpn_server_admin_ui_https_port" { default = 943 }
variable "openvpn_server_client_ui_https_port" { default = 943 }
variable "openvpn_server_cluster_port" { default = 945 }
variable "openvpn_server_daemon_tcp_port" { default = 443 }
variable "openvpn_server_daemon_udp_port" { default = 1194 }
variable "openvpn_timezone" { default = "America/Chicago" }
variable "openvpn_web_server_name" { default = "OpenVPN Server" }
variable "rds_mysql_instance_address" { default = null }
variable "rds_secretsmanager_version_arn" {default = null}
variable "rds_secretsmanager_kms_key_arn" {default = null}
variable "rds_secretsmanager_secret_admin_password_keyname" { default = "ADMIN_PASSWORD" }
variable "rds_secretsmanager_secret_admin_username_keyname" { default = "ADMIN_USERNAME" }
variable "rds_secretsmanager_secret_port_keyname" { default = "PORT" }
variable "rds_security_group_id" { default = null }
variable "ssl_certificate_secretsmanager_version_arn" {default = null}
variable "ssl_certificate_secretsmanager_kms_key_arn" {default = null}
variable "ssl_certificate_secretsmanager_secret_certificate_bundle_keyname" { default = "CERTIFICATE_CHAIN" }
variable "ssl_certificate_secretsmanager_secret_certificate_keyname" { default = "CERTIFICATE" }
variable "ssl_certificate_secretsmanager_secret_certificate_private_key_keyname" { default = "CERTIFICATE_PRIVATE_KEY" }
