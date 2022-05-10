module "ec2_autoscale_group_scripts_bucket_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.ec2_autoscale_group_meta.context
  attributes = ["scripts"]
}


#------------------------------------------------------------------------------
# VPN ASG Scripts Bucket
#------------------------------------------------------------------------------
module "ec2_autoscale_group_scripts_bucket" {
  source  = "registry.terraform.io/cloudposse/s3-bucket/aws"
  version = "0.47.0"
  context = module.ec2_autoscale_group_scripts_bucket_meta.context

  acl                          = "private"
  allow_encrypted_uploads_only = false
  allow_ssl_requests_only      = false
  allowed_bucket_actions = [
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:GetObject",
    "s3:CreateMultipartUpload",
    "s3:DeleteObject",
    "s3:ListBucket",
    "s3:ListBucketMultipartUploads",
    "s3:GetBucketLocation",
    "s3:AbortMultipartUpload"
  ]
  block_public_acls   = true
  block_public_policy = true
  bucket_name         = null
  cors_rule_inputs    = null
  force_destroy       = false
  grants              = null
  ignore_public_acls  = true
  kms_master_key_arn  = ""
  #  lifecycle_rules = [
  #    {
  #      abort_incomplete_multipart_upload_days : local.log_expiration_days,
  #      deeparchive_transition_days : local.log_expiration_days,
  #      enable_current_object_expiration : true,
  #      enable_deeparchive_transition : false,
  #      enable_glacier_transition : false,
  #      enable_standard_ia_transition : false,
  #      enabled : false,
  #      expiration_days : local.log_expiration_days,
  #      glacier_transition_days : local.log_glacier_transition_days,
  #      noncurrent_version_deeparchive_transition_days : local.log_glacier_transition_days,
  #      noncurrent_version_expiration_days : local.log_expiration_days,
  #      noncurrent_version_glacier_transition_days : local.log_retention_days,
  #      prefix : "",
  #      standard_transition_days : local.log_standard_transition_days,
  #      tags : {}
  #    }
  #  ]
  #  logging = {
  #    bucket_name =
  #    prefix      =
  #  }
  object_lock_configuration = null
  policy                    = ""
  restrict_public_buckets   = true
  s3_replica_bucket_arn     = ""
  s3_replication_enabled    = false
  sse_algorithm             = "AES256"
  user_enabled              = false
  versioning_enabled        = true
}

resource "aws_s3_bucket_object" "ec2_init_script_without_rds" {
  count  = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "init.sh"
  content = templatefile("${path.module}/scripts/init.sh.tftpl", {
    hostname                                  = var.openvpn_hostname //module.ec2_autoscale_group_dns_meta.id,
    openvpn_secretsmanager_secret_version_arn = join("", data.aws_secretsmanager_secret_version.ec2_autoscale_group.*.arn)
    region                                    = data.aws_region.current[0].name
  })
}

resource "aws_s3_bucket_object" "openvpn_init_script" {
  count  = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "openvpn-init.sh"
  content = templatefile("${path.module}/scripts/openvpn-init.sh.tftpl", {
    hostname                     = var.openvpn_hostname //module.ec2_autoscale_group_dns_meta.id,
    webserver_name               = var.openvpn_web_server_name,
    cluster_port                 = var.openvpn_cluster_port,
    users                        = var.openvpn_users,
    groups                       = var.openvpn_groups,
    ui_https_port                = var.openvpn_ui_https_port,
    daemon_udp_port              = var.openvpn_daemon_udp_port,
    daemon_tcp_port              = var.openvpn_daemon_tcp_port,
    client_dhcp_network          = var.openvpn_client_dhcp_network,
    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    client_group_dhcp_cidr_block = var.openvpn_client_group_dhcp_cidr_block,
    client_static_network        = var.openvpn_client_static_network,
    client_static_network_mask   = var.openvpn_client_static_network_mask,
    dhcp_option_domain           = var.openvpn_dhcp_option_domain,
    secret_arn                   = join("", data.aws_secretsmanager_secret_version.ec2_autoscale_group.*.arn),
    region                       = data.aws_region.current[0].name,
    openvpn_client_cidr_blocks   = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks              = join(" ", var.vpc_cidr_blocks)
  })
}

resource "aws_s3_bucket_object" "openvpn_init_mysql_script" {
  #count = module.ec2_autoscale_group_scripts_bucket_meta.enabled && var.rds_mysql_instance_address != null ? 1 : 0
    count  = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "openvpn-init-mysql.sh"
  content = templatefile("${path.module}/scripts/openvpn-init-mysql.sh.tftpl", {
    rds_host               = var.rds_mysql_instance_address,
    rds_secret_arn         = var.rds_secret_arn
    rds_admin_username_key = var.rds_secret_admin_username_keyname
    rds_admin_password_key = var.rds_secret_admin_password_keyname
    rds_port_key           = var.rds_secret_port_keyname
    region                 = length(data.aws_region.current) > 0 ? one(data.aws_region.current[*].name) : ""
  })
}

data "aws_secretsmanager_secret" "ssl" {
  count = module.ec2_autoscale_group_scripts_bucket_meta.enabled && var.ssl_secret_arn != null ? 1 : 0
  #  count = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  arn = var.ssl_secret_arn
}

data "aws_secretsmanager_secret_version" "ssl_version" {
  count = module.ec2_autoscale_group_scripts_bucket_meta.enabled && var.ssl_secret_arn != null ? 1 : 0
  #  count         = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  secret_id     = data.aws_secretsmanager_secret.ssl[0].id
  version_stage = "AWSCURRENT"
}

resource "aws_s3_bucket_object" "ssl_cert_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_meta.enabled && var.ssl_secret_arn != null ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "ssl-cert.sh"
  content = templatefile("${path.module}/scripts/ssl-cert.sh.tftpl", {
    secretsmanager_secret_version_arn = data.aws_secretsmanager_secret_version.ssl_version[0].arn,
    region                            = data.aws_region.current[0].name,
    certificate_keyname               = var.ssl_secret_certificate_keyname
    certificate_bundle_keyname        = var.ssl_secret_certificate_bundle_keyname
    certificate_private_key_keyname   = var.ssl_secret_certificate_private_key_keyname
  })
}

