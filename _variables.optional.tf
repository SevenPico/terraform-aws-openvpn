
variable "ec2_user_data" {
  type    = string
  default = ""
}

variable "openvpn_ui_ingress_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "openvpn_daemon_ingress_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}
variable "openvpn_config_scripts" {
  type = list(string)
  default = [
    "init.sh",
    "openvpn.sh"
  ]
}

variable "associate_public_ip_address" {
  type    = bool
  default = true
}

variable "create_admin_secret" { default = false }
variable "secret_enable_key_rotation" { default = true }

variable "secret_arn" {
  type    = string
  default = ""
}

variable "secret_kms_key_arn" {
  type    = string
  default = null
}

variable "secret_admin_password_key" {
  type    = string
  default = "ADMIN_PASSWORD"
}

variable "ami_id" { default = "ami-037ff6453f0855c46" } # "This module was built using ami-037ff6453f0855c46 which is a BYOL, but supports 2 free connections."
variable "autoscale_desired_count" { default = 1 }
variable "autoscale_instance_type" { default = "t3.micro" }
variable "autoscale_max_count" { default = 1 }
variable "autoscale_min_count" { default = 1 }
variable "autoscale_sns_topic_default_result" { default = "CONTINUE" }
variable "autoscale_sns_topic_heartbeat_timeout" { default = 180 }
variable "create_autoscale_sns_topic" { default = false }

variable "openvpn_daemon_tcp_port" { default = 443 }
variable "openvpn_daemon_udp_port" { default = 1194 }
variable "openvpn_time_zone" { default = "America/Chicago" }
variable "openvpn_ui_https_port" { default = 943 }
variable "openvpn_web_server_name" { default = "OpenVPN Server" }
variable "openvpn_ssm_association_output_bucket_name" { default = null }

variable "openvpn_client_cidr_blocks" { default = ["172.27.0.0/16"] }


variable "s3_access_logs_prefix" {
  type        = string
  default     = ""
  description = "The S3 log bucket prefix"
}

variable "s3_access_logs_s3_bucket_id" {
  type        = string
  default     = null
  description = "An external S3 Bucket name to store access logs in. If specified, no logging bucket will be created."
}

variable "cloudwatch_logs_expiration_days" { default = 90 }

variable "s3_versioning_enabled" { default = true }
variable "s3_force_destroy" { default = true }

/*
Schema for lifecycle_configuration_rules
{
  enabled = true # bool
  id      = string
  abort_incomplete_multipart_upload_days = null # number
  filter_and = {
    object_size_greater_than = null # integer >= 0
    object_size_less_than    = null # integer >= 1
    prefix                   = null # string
    tags                     = {}   # map(string)
  }
  expiration = {
    date                         = null # string, RFC3339 time format, GMT
    days                         = null # integer > 0
    expired_object_delete_marker = null # bool
  }
  noncurrent_version_expiration = {
    newer_noncurrent_versions = null # integer > 0
    noncurrent_days           = null # integer >= 0
  }
  transition = [{
    date          = null # string, RFC3339 time format, GMT
    days          = null # integer >= 0
    storage_class = null # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
  }]
  noncurrent_version_transition = [{
    newer_noncurrent_versions = null # integer >= 0
    noncurrent_days           = null # integer >= 0
    storage_class             = null # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
  }]
}
We only partly specify the object to allow for compatible future extension.
*/

variable "s3_lifecycle_configuration_rules" {
  type = list(object({
    enabled = bool
    id      = string

    abort_incomplete_multipart_upload_days = number

    # `filter_and` is the `and` configuration block inside the `filter` configuration.
    # This is the only place you should specify a prefix.
    filter_and = any
    expiration = any
    transition = list(any)

    noncurrent_version_expiration = any
    noncurrent_version_transition = list(any)
  }))
  description = "A list of lifecycle V2 rules"
  default = [{
    enabled = true # bool
    id      = "v2rule"

    abort_incomplete_multipart_upload_days = 1 # number

    filter_and = null
    expiration = {
      days = 120 # integer > 0
    }
    noncurrent_version_expiration = {
      newer_noncurrent_versions = 3  # integer > 0
      noncurrent_days           = 60 # integer >= 0
    }
    transition = [{
      days          = 30            # integer >= 0
      storage_class = "STANDARD_IA" # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
      },
      {
        days          = 60           # integer >= 0
        storage_class = "ONEZONE_IA" # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
    }]
    noncurrent_version_transition = [{
      newer_noncurrent_versions = 3            # integer >= 0
      noncurrent_days           = 30           # integer >= 0
      storage_class             = "ONEZONE_IA" # string/enum, one of GLACIER, STANDARD_IA, ONEZONE_IA, INTELLIGENT_TIERING, DEEP_ARCHIVE, GLACIER_IR.
    }]
  }]
}

variable "create_nlb" { default = false }
variable "nlb_subnet_ids" { default = [] }
variable "nlb_acm_certificate_arn" { default = null }
variable "nlb_tls_ssl_policy" { default = "ELBSecurityPolicy-TLS13-1-1-2021-06" }
variable "nlb_access_logs_enabled" { default = true }
variable "nlb_deletion_protection_enabled" { default = false }
