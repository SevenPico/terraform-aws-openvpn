module "ec2_autoscale_group_scripts_bucket_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.ec2_autoscale_group_context.self
  attributes = ["scripts"]
}


locals {
  init_sh    = try(join("", aws_s3_object.init_sh[*].key), "")
  install_sh = try(join("", aws_s3_object.install_sh[*].key), "")
  openvpn_sh = try(join("", aws_s3_object.openvpn_sh[*].key), "")
  static_sh  = try(join("", aws_s3_object.static_client_addresses_sh[*].key), "")

  openvpn_config_scripts = concat(compact([
    local.init_sh,
    local.install_sh,
    local.openvpn_sh,
    local.static_sh
  ]), var.openvpn_config_scripts_additional)
}

# ------------------------------------------------------------------------------
# Openvpn S3 Bucket Policy
# ------------------------------------------------------------------------------
data "aws_iam_policy_document" "deployer_artifacts_bucket" {
  count = module.context.enabled ? 1 : 0

  statement {
    sid     = "ForceSSLOnlyAccess"
    effect  = "Deny"
    actions = ["s3:*"]
    resources = [
      module.ec2_autoscale_group_scripts_bucket.bucket_arn,
      "${module.ec2_autoscale_group_scripts_bucket.bucket_arn}/*"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      values   = ["false"]
      variable = "aws:SecureTransport"
    }
  }
}


#------------------------------------------------------------------------------
# VPN ASG Scripts Bucket
#------------------------------------------------------------------------------
module "ec2_autoscale_group_scripts_bucket" {
  source  = "app.terraform.io/SevenPico/s3-bucket/aws"
  version = "3.1.8"
  context = module.ec2_autoscale_group_scripts_bucket_context.self

  acl                          = "private"
  allow_encrypted_uploads_only = false
  allow_ssl_requests_only      = false
  allowed_bucket_actions = [
    "s3:PutObject",
    "s3:PutObjectAcl",
    "s3:GetObject",
    "s3:DeleteObject",
    "s3:ListBucket",
    "s3:ListBucketMultipartUploads",
    "s3:GetBucketLocation",
    "s3:AbortMultipartUpload"
  ]
  block_public_acls             = true
  block_public_policy           = true
  bucket_key_enabled            = false
  bucket_name                   = null
  cors_rule_inputs              = null
  enable_mfa_delete             = var.openvpn_enable_mfa_delete
  force_destroy                 = var.openvpn_s3_force_destroy
  grants                        = []
  ignore_public_acls            = true
  kms_master_key_arn            = ""
  lifecycle_configuration_rules = var.openvpn_s3_lifecycle_configuration_rules
  logging = var.openvpn_s3_access_logs_s3_bucket_id != null ? {
    bucket_name = var.openvpn_s3_access_logs_s3_bucket_id
    prefix      = var.openvpn_s3_access_logs_prefix_override
  } : null
  object_lock_configuration     = null
  privileged_principal_actions  = []
  privileged_principal_arns     = []
  restrict_public_buckets       = true
  s3_object_ownership           = var.openvpn_s3_object_ownership
  s3_replica_bucket_arn         = ""
  s3_replication_enabled        = false
  s3_replication_rules          = null
  s3_replication_source_roles   = []
  source_policy_documents       = concat([one(data.aws_iam_policy_document.deployer_artifacts_bucket[*].json)], var.openvpn_s3_source_policy_documents)
  sse_algorithm                 = "AES256"
  transfer_acceleration_enabled = false
  user_enabled                  = false
  versioning_enabled            = var.openvpn_s3_versioning_enabled
  website_inputs                = null
  wait_time_seconds             = 120
}

resource "aws_s3_object" "init_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_context.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "init.sh"
  content = templatefile("${path.module}/scripts/init.sh.tftpl", {
    hostname = var.openvpn_hostname
  })
  depends_on = [module.ec2_autoscale_group_scripts_bucket]
}

resource "aws_s3_object" "install_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_context.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "install.sh"
  content = templatefile("${path.module}/scripts/install.sh.tftpl", {
    openvpnas_version         = var.openvpn_version
    efs_mount_target_dns_name = module.efs.mount_target_dns_names[0],
  })
  depends_on = [module.ec2_autoscale_group_scripts_bucket]
}

resource "aws_s3_object" "openvpn_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_context.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "openvpn.sh"
  content = templatefile("${path.module}/scripts/openvpn.sh.tftpl", {
    hostname                   = var.openvpn_hostname
    webserver_name             = var.openvpn_web_server_name,
    ui_https_port              = var.openvpn_ui_https_port,
    daemon_udp_port            = var.openvpn_daemon_udp_port,
    daemon_tcp_port            = var.openvpn_daemon_tcp_port,
    dhcp_option_domain         = var.openvpn_dhcp_option_domain,
    client_dhcp_network        = var.openvpn_client_dhcp_network
    client_dhcp_network_mask   = var.openvpn_client_dhcp_network_mask
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
    password_secret_arn        = local.secret_arn
    password_secret_key        = var.openvpn_secret_admin_password_key
    region                     = local.current_region
    tls_version_min            = var.openvpn_tls_version_min
    enable_vpn_server_nat      = var.openvpn_enable_server_nat
  })
  depends_on = [module.ec2_autoscale_group_scripts_bucket]
}

resource "aws_s3_object" "static_client_addresses_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_context.enabled && var.openvpn_client_static_addresses_enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "static-client-addresses.sh"
  content = templatefile("${path.module}/scripts/static-client-addresses.sh.tftpl", {
    client_static_network      = var.openvpn_client_static_network,
    client_static_network_mask = var.openvpn_client_static_network_mask
  })
  depends_on = [module.ec2_autoscale_group_scripts_bucket]
}
