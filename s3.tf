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

resource "aws_s3_object" "init_sh" {
  count  = module.ec2_autoscale_group_scripts_bucket_meta.enabled ? 1 : 0
  bucket = module.ec2_autoscale_group_scripts_bucket.bucket_id
  key    = "init.sh"
  content = templatefile("${path.module}/scripts/init.sh.tftpl", {
    hostname   = var.openvpn_hostname
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
  })
}
