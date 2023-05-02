## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./_variables.optional.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------


#------------------------------------------------------------------------------
# Create Options
#------------------------------------------------------------------------------
variable "create_ec2_autoscale_sns_topic" {
  type    = bool
  default = true
}

variable "create_nlb" {
  type    = bool
  default = false
}

variable "create_openvpn_secret" {
  type    = bool
  default = true
}


#------------------------------------------------------------------------------
# Enablements
#------------------------------------------------------------------------------
variable "enable_efs" {
  type    = bool
  default = false
}

variable "enable_nat" {
  type        = bool
  default     = true
  description = <<EOF
  When this is true network address translation is enabled. Clients will be able to reach endpoints in the VPC.
  When this is False reverse routing will be enabled and clients will be able to be access from endpoints in the VPC
  as long as the VPC route tables have updated.
EOF
}

variable "enable_custom_ssl" {
  type        = bool
  default     = true
  description = <<EOF
  When this is true SSL values from the SSL SecretsManager document will be written to the EC2 Instance and OpenVPN will
  use the Certificate instead of default OpenVPN Certificate.
EOF
}

variable "enable_licensing" {
  type        = bool
  default     = true
  description = "When this is true the openvpn license will be retrieve from OpenPVN SecretsManager Document."
}

variable "enable_mysql" {
  type        = bool
  default     = false
  description = "When this is true ``rds_mysql_instance_address`` ``rds_secret_arn`` ``rds_security_group_id`` ``rds_secret_kms_key_arn`` are required."
}

variable "enable_openvpn_backups" {
  type    = bool
  default = false
}

variable "enable_ec2_cloudwatch_logs" {
  type    = bool
  default = true
}

variable "cloudwatch_logs_expiration_days" {
  type    = number
  default = 90
}

variable "enable_ssl_cert_updater" {
  type    = bool
  default = false
}


#------------------------------------------------------------------------------
# SSL Inputs
#------------------------------------------------------------------------------
variable "ssl_secret_arn" {
  type    = string
  default = ""
}

variable "ssl_secret_kms_key_arn" {
  type    = string
  default = ""
}

variable "ssl_secret_certificate_bundle_keyname" {
  type    = string
  default = "CERTIFICATE_CHAIN"
}

variable "ssl_secret_certificate_keyname" {
  type    = string
  default = "CERTIFICATE"
}

variable "ssl_secret_certificate_private_key_keyname" {
  type    = string
  default = "CERTIFICATE_PRIVATE_KEY"
}


#------------------------------------------------------------------------------
# EC2 Inputs
#------------------------------------------------------------------------------
variable "ec2_associate_public_ip_address" {
  type    = bool
  default = true
}

variable "ec2_ami_id" {
  type    = string
  default = "ami-0574da719dca65348"
}

variable "ec2_autoscale_desired_count" {
  type    = number
  default = 1
}

variable "ec2_autoscale_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "ec2_autoscale_max_count" {
  type    = number
  default = 1
}

variable "ec2_autoscale_min_count" {
  type    = number
  default = 1
}

variable "ec2_autoscale_sns_topic_default_result" {
  type    = string
  default = "CONTINUE"
}

variable "ec2_autoscale_sns_topic_heartbeat_timeout" {
  type    = number
  default = 180
}

variable "ec2_additional_security_group_ids" {
  type    = list(string)
  default = []
}

variable "ec2_disable_api_termination" {
  type        = bool
  description = "If `true`, enables EC2 Instance Termination Protection"
  default     = false
}

variable "ec2_upgrade_schedule_expression" {
  type    = string
  default = "cron(15 13 ? * SUN *)"
}

variable "ec2_security_group_allow_all_egress" {
  type    = bool
  default = true
}

variable "ec2_security_group_rules" {
  type    = list(any)
  default = []
}

variable "ec2_additional_instance_role_policies" {
  type    = any
  default = []
}

variable "ec2_block_device_mappings" {
  description = "Specify volumes to attach to the instance besides the volumes specified by the AMI"
  type = list(object({
    device_name  = string
    no_device    = bool
    virtual_name = string
    ebs = object({
      delete_on_termination = bool
      encrypted             = bool
      iops                  = number
      kms_key_id            = string
      snapshot_id           = string
      volume_size           = number
      volume_type           = string
    })
  }))

  default = []
}


#------------------------------------------------------------------------------
# NLB Inputs
#------------------------------------------------------------------------------
variable "nlb_access_logs_prefix_override" {
  type    = string
  default = null
}

variable "nlb_access_logs_s3_bucket_id" {
  type    = string
  default = null
}

variable "nlb_acm_certificate_arn" {
  type    = string
  default = null
}

variable "nlb_deletion_protection_enabled" {
  type    = bool
  default = false
}

variable "nlb_subnet_ids" {
  type    = list(string)
  default = []
}

variable "nlb_tls_ssl_policy" {
  type    = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}



#------------------------------------------------------------------------------
# S3 Inputs
#------------------------------------------------------------------------------
variable "s3_source_policy_documents" {
  type        = list(string)
  default     = []
  description = <<-EOT
    List of IAM policy documents that are merged together into the exported document.
    Statements defined in source_policy_documents must have unique SIDs.
    Statement having SIDs that match policy SIDs generated by this module will override them.
    EOT
}

variable "s3_access_logs_prefix_override" {
  type    = string
  default = null
}

variable "s3_access_logs_s3_bucket_id" {
  type    = string
  default = null
}

variable "s3_force_destroy" {
  type    = bool
  default = true
}

variable "s3_lifecycle_configuration_rules" {
  type    = list(any)
  default = []
}

variable "s3_versioning_enabled" {
  type    = bool
  default = true
}

variable "s3_object_ownership" {
  type    = string
  default = "BucketOwnerEnforced"
}


#------------------------------------------------------------------------------
# OpenVPN Configuration Inputs
#------------------------------------------------------------------------------
variable "openvpn_backup_schedule_expression" {
  type    = string
  default = "cron(0 00 00 ? * * *)"
}

variable "openvpn_client_cidr_blocks" {
  type    = list(string)
  default = ["172.27.0.0/16"]
}

variable "openvpn_client_dhcp_network" {
  type    = string
  default = "172.27.32.0"
}

variable "openvpn_client_dhcp_network_mask" {
  type    = string
  default = "20"
}

variable "openvpn_client_static_addresses_enabled" {
  type    = bool
  default = false
}

variable "openvpn_client_static_network" {
  type    = string
  default = "172.27.64.0"
}

variable "openvpn_client_static_network_mask" {
  type    = string
  default = "20"
}

variable "openvpn_daemon_ingress_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "openvpn_daemon_tcp_port" {
  type    = number
  default = 443
}

variable "openvpn_daemon_udp_port" {
  type    = number
  default = 1194
}

variable "openvpn_secret_admin_password_key" {
  type    = string
  default = "ADMIN_PASSWORD"
}

variable "openvpn_secret_arn" {
  type    = string
  default = ""
}

variable "openvpn_secret_enable_kms_key_rotation" {
  type    = bool
  default = true
}

variable "openvpn_secret_kms_key_arn" {
  type    = string
  default = null
}

variable "openvpn_time_zone" {
  type    = string
  default = "America/Chicago"
}

variable "openvpn_ui_https_port" {
  type    = number
  default = 943
}

variable "openvpn_ui_ingress_blocks" {
  type    = list(string)
  default = ["0.0.0.0/0"]
}

variable "openvpn_web_server_name" {
  type    = string
  default = "OpenVPN Server"
}

variable "openvpn_s3_object_ownership" {
  type    = string
  default = "BucketOwnerEnforced"
}

variable "openvpn_tls_version_min" {
  type    = string
  default = "1.2"
}

//variable "openvpn_enable_server_nat" {
//  type    = bool
//  default = true
//}

variable "openvpn_version" {
  type    = string
  default = "2.11.1-f4027f58-Ubuntu22"
}

variable "openvpn_ssm_association_output_bucket_name" {
  type    = string
  default = null
}


#------------------------------------------------------------------------------
# Mysql Configuration Inputs
#------------------------------------------------------------------------------
variable "rds_secret_admin_password_keyname" {
  default = "ADMIN_PASSWORD"
}

variable "rds_secret_admin_username_keyname" {
  default = "ADMIN_USERNAME"
}

variable "rds_secret_port_keyname" {
  default = "PORT"
}

variable "rds_mysql_instance_address" {
  type        = string
  default     = ""
  description = "Required when ``enable_mysql = true`"
}

variable "rds_secret_arn" {
  type        = string
  default     = ""
  description = "Required when ``enable_mysql = true`"
}

variable "rds_secret_kms_key_arn" {
  type        = string
  default     = ""
  description = "Required when ``enable_mysql = true`"
}
