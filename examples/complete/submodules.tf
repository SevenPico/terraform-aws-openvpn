module "mysql_config_script" {
  source  = "../../modules/mysql-config-script"
  context = module.this.context

  bucket_id                  = module.openvpn.ssm_script_bucket_id
  script_name                = "mysql.sh"
  ec2_role_name               = module.openvpn.autoscaling_role_name
  rds_mysql_instance_address = module.rds.instance_address
  rds_secret_arn             = join("", aws_secretsmanager_secret.rds[*].arn)
  rds_secret_kms_key_arn     = join("", aws_kms_key.rds[*].arn)
  rds_security_group_id      = module.rds.security_group_id
}

module "ssh_config_script" {
  source  = "../../modules/ssl-config-script"
  context = module.this.context

  bucket_id              = module.openvpn.ssm_script_bucket_id
  script_name            = "ssh.sh"
  ec2_role_name           = module.openvpn.autoscaling_role_name
  ssl_secret_arn         = module.ssl_certificate.secret_arn
  ssl_secret_kms_key_arn = module.ssl_certificate.kms_key_arn
}
