#------------------------------------------------------------------------------
# EC2 VPN RDS Labels
#------------------------------------------------------------------------------
module "rds_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.this.context
  name    = "rds"
  enabled = var.rds_use_mysql_backend
}

module "rds_secrets_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.rds_meta.context
  attributes = ["configuration"]
}

module "rds_dns_meta" {
  source  = "registry.terraform.io/cloudposse/label/null"
  version = "0.25.0"
  context = module.dns_meta.context

  name = "${module.rds_meta.stage}-${module.rds_meta.name}"
}


#------------------------------------------------------------------------------
# EC2 VPN RDS Secrets
#------------------------------------------------------------------------------
resource "aws_secretsmanager_secret" "rds" {
  count       = module.rds_meta.enabled ? 1 : 0
  name_prefix = "${module.rds_secrets_meta.id}-"
  tags        = module.rds_secrets_meta.tags
  kms_key_id  = aws_kms_key.rds[0].id
  description = "Environment Variables for  ${title(module.rds_meta.id_full)}"
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_secretsmanager_secret_version" "rds" {
  count     = module.rds_meta.enabled ? 1 : 0
  secret_id = aws_secretsmanager_secret.rds[0].id
  lifecycle {
    ignore_changes  = [secret_string, secret_binary]
    prevent_destroy = false
  }
  secret_string = jsonencode({
    ADMIN_USERNAME = var.rds_admin_username
    ADMIN_PASSWORD = var.rds_admin_password
    PORT           = var.rds_port
  })
}

data "aws_secretsmanager_secret_version" "rds" {
  count         = module.rds_meta.enabled ? 1 : 0
  depends_on    = [aws_secretsmanager_secret_version.rds]
  secret_id     = aws_secretsmanager_secret.rds[0].id
  version_stage = "AWSCURRENT"
}


#------------------------------------------------------------------------------
# EC2 VPN RDS
#------------------------------------------------------------------------------
resource "aws_kms_key" "rds" {
  count                   = module.rds_meta.enabled ? 1 : 0
  description             = "${module.rds_meta.id}-key"
  deletion_window_in_days = 30
  tags                    = module.rds_meta.tags
}

locals {
  db_name = replace(module.rds_meta.id, "-", "_")
}

module "rds" {
  source  = "registry.terraform.io/cloudposse/rds/aws"
  version = "0.38.4"
  context = module.rds_meta.context

  #Required
  allocated_storage            = 100
  associate_security_group_ids = []
  database_name                = local.db_name
  database_port                = var.rds_port
  db_parameter_group           = "mysql8.0"
  engine                       = "mysql"
  engine_version               = "8.0.23"
  instance_class               = "db.t2.small"
  security_group_ids           = []
  subnet_ids                   = module.vpc_subnets.private_subnet_ids
  vpc_id                       = module.vpc.vpc_id

  # Optional
  allow_major_version_upgrade           = false
  allowed_cidr_blocks                   = []
  apply_immediately                     = true
  auto_minor_version_upgrade            = true
  backup_retention_period               = 30
  backup_window                         = "03:00-06:00"
  ca_cert_identifier                    = "rds-ca-2019"
  copy_tags_to_snapshot                 = true
  database_password                     = var.rds_admin_password
  database_user                         = var.rds_admin_username
  db_options                            = []
  db_parameter                          = []
  deletion_protection                   = false
  dns_zone_id                           = aws_route53_zone.private[0].id
  enabled_cloudwatch_logs_exports       = []
  final_snapshot_identifier             = ""
  host_name                             = module.rds_dns_meta.id
  iam_database_authentication_enabled   = false
  iops                                  = 0
  kms_key_arn                           = module.rds_meta.enabled ? aws_kms_key.rds[0].arn : ""
  license_model                         = ""
  maintenance_window                    = "Mon:00:00-Mon:03:00"
  major_engine_version                  = "8.0"
  max_allocated_storage                 = 0
  monitoring_interval                   = 0
  monitoring_role_arn                   = ""
  multi_az                              = false
  option_group_name                     = ""
  parameter_group_name                  = ""
  performance_insights_enabled          = false
  performance_insights_kms_key_id       = ""
  performance_insights_retention_period = 30
  publicly_accessible                   = false
  skip_final_snapshot                   = true
  snapshot_identifier                   = ""
  storage_encrypted                     = true
  storage_type                          = "gp2"
}

resource "aws_security_group_rule" "allow_ingress_from_openvpn_ec2_to_mysql_backend" {
  count                    = module.rds_meta.enabled ? 1 : 0
  security_group_id        = module.rds.security_group_id
  type                     = "ingress"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "tcp"
  source_security_group_id = module.autoscaled_ec2_openvpn.ec2_security_group_id
  self                     = null
  description              = "Allow connections from ${module.this.id}"
}

resource "aws_security_group_rule" "allow_egress_from_openvpn_ec2_to_mysql_backend" {
  count                    = module.rds_meta.enabled ? 1 : 0
  security_group_id        = module.autoscaled_ec2_openvpn.ec2_security_group_id
  type                     = "egress"
  from_port                = var.rds_port
  to_port                  = var.rds_port
  protocol                 = "tcp"
  source_security_group_id = module.rds.security_group_id
  self                     = null
  description              = "Allow connections to ${module.rds_meta.id}"
}
