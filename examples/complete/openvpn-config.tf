locals {
  mysql_script_name   = "mysql.sh"
  ssl_script_name     = "ssl.sh"
  license_script_name = "license.sh"
  network_script_name = "network.sh"
}


module "openvpn_mysql_config_script" {
  source     = "../../modules/mysql-config-script"
  context    = module.this.context
  depends_on = [module.openvpn]

  bucket_id                  = module.openvpn.ssm_script_bucket_id
  script_name                = local.mysql_script_name
  ec2_role_name              = module.openvpn.role_name
  rds_mysql_instance_address = module.rds.instance_address
  rds_secret_arn             = join("", aws_secretsmanager_secret.rds[*].arn)
  rds_secret_kms_key_arn     = join("", aws_kms_key.rds[*].arn)
  rds_security_group_id      = module.rds.security_group_id
}

module "openvpn_ssl_config_script" {
  source     = "../../modules/ssl-config-script"
  context    = module.this.context
  depends_on = [module.openvpn]

  bucket_id              = module.openvpn.ssm_script_bucket_id
  script_name            = local.ssl_script_name
  ec2_role_name          = module.openvpn.role_name
  ssl_secret_arn         = module.ssl_certificate.secret_arn
  ssl_secret_kms_key_arn = module.ssl_certificate.kms_key_arn
}

module "openvpn_license_import_script" {
  source     = "../../modules/license-import-script"
  context    = module.this.context
  depends_on = [module.openvpn]

  bucket_id           = module.openvpn.ssm_script_bucket_id
  script_name         = local.license_script_name
  ec2_role_name       = module.openvpn.role_name
  secrets_arn         = one(aws_secretsmanager_secret.openvpn[*].arn)
  secrets_kms_key_arn = module.openvpn_secret_kms_key.key_arn
}


module "openvpn_network_config_script" {
  source     = "../../modules/network-config-script"
  context    = module.this.context
  depends_on = [module.openvpn]

  bucket_id                            = module.openvpn.ssm_script_bucket_id
  script_name                          = local.network_script_name
  ec2_role_name                        = module.openvpn.role_name
  openvpn_client_dhcp_network          = var.openvpn_client_dhcp_network
  openvpn_client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask
  openvpn_client_group_dhcp_cidr_block = var.openvpn_client_group_dhcp_cidr_block
  openvpn_client_static_network        = var.openvpn_client_static_network
  openvpn_client_static_network_mask   = var.openvpn_client_static_network_mask
  openvpn_client_cidr_blocks           = var.openvpn_client_cidr_blocks
  vpc_cidr_blocks                      = [module.vpc.vpc_cidr_block]
}
