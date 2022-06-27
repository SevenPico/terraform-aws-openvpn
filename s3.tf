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
  version = "2.0.2"

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
  force_destroy                 = var.s3_force_destroy
  grants                        = []
  ignore_public_acls            = true
  kms_master_key_arn            = ""
  lifecycle_configuration_rules = var.s3_lifecycle_configuration_rules
  logging = var.s3_access_logs_s3_bucket_id != null ? {
    bucket_name = var.s3_access_logs_s3_bucket_id
    prefix      = var.s3_access_logs_prefix
  } : null
  object_lock_configuration     = null
  privileged_principal_actions  = []
  privileged_principal_arns     = []
  restrict_public_buckets       = true
  s3_object_ownership           = "BucketOwnerPreferred"
  s3_replica_bucket_arn         = ""
  s3_replication_enabled        = false
  s3_replication_rules          = null
  s3_replication_source_roles   = []
  source_policy_documents       = []
  sse_algorithm                 = "AES256"
  transfer_acceleration_enabled = false
  user_enabled                  = false
  versioning_enabled            = var.s3_versioning_enabled
  website_inputs                = null
}

resource "aws_s3_object" "init_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "init.sh"
  content = templatefile("${path.module}/scripts/init.sh.tftpl", {
    hostname = var.openvpn_hostname
  })
}

resource "aws_s3_object" "openvpn_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "openvpn.sh"
  content = templatefile("${path.module}/scripts/openvpn.sh.tftpl", {
    hostname                   = var.openvpn_hostname
    webserver_name             = var.openvpn_web_server_name,
    ui_https_port              = var.openvpn_ui_https_port,
    daemon_udp_port            = var.openvpn_daemon_udp_port,
    daemon_tcp_port            = var.openvpn_daemon_tcp_port,
    dhcp_option_domain         = var.openvpn_dhcp_option_domain,
    openvpn_client_cidr_blocks = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks            = join(" ", var.vpc_cidr_blocks)
    password_secret_arn        = local.secret_arn
    password_secret_key        = var.secret_admin_password_key
    region                     = local.current_region
  })
}
