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

variable "create_ec2_autoscale_sns_topic" { default = false }
variable "create_nlb" { default = false }
variable "create_openvpn_secret" { default = false }

variable "enable_efs" { default = true }
variable "enable_nat" {
  description = <<EOF
  When this is true network address translation is enabled. Clients will be able to reach endpoints in the VPC.
  When this is False reverse routing will be enabled and clients will be able to be access from endpoints in the VPC
  as long as the VPC route tables have updated.
EOF
}
variable "enable_custom_ssl" {
  description = <<EOF
  When this is true SSL values from the SSL SecretsManager document will be written to the EC2 Instance and OpenVPN will
  use the Certificate instead of default OpenVPN Certificate.
EOF
}
variable "enable_licensing" {
  description = "When this is true the openvpn license will be retrieve from OpenPVN SecretsManager Document."
}
variable "enable_openvpn_backups" { default = true }
variable "enable_ec2_cloudwatch_logs" { default = true }
variable "cloudwatch_logs_expiration_days" { default = 90 }


#------------------------------------------------------------------------------
# EC2 Inputs
#------------------------------------------------------------------------------
variable "ec2_user_data" { default = "" } #Create Local variable
variable "ec2_associate_public_ip_address" { default = true }
variable "ec2_ami_id" { default = "ami-0574da719dca65348" }
variable "ec2_autoscale_desired_count" { default = 1 }
variable "ec2_autoscale_instance_type" { default = "t3.micro" }
variable "ec2_autoscale_max_count" { default = 1 }
variable "ec2_autoscale_min_count" { default = 1 }
variable "ec2_autoscale_sns_topic_default_result" { default = "CONTINUE" }
variable "ec2_autoscale_sns_topic_heartbeat_timeout" { default = 180 }
variable "ec2_additional_security_group_ids" { default = [] }
variable "ec2_key_name" { default = null }
variable "ec2_initialization_schedule_expression" { default = null }
variable "ec2_upgrade_schedule_expression" { default = "cron(15 13 ? * SUN *)" }
#variable "ec2_preserve_security_group_id" { default = false }     // when true, minimizes security group destroys.  default to false for backwards compatibility
variable "ec2_security_group_allow_all_egress" { default = true } //for backwards compatibility
variable "ec2_security_group_rules" {
  type    = list(any)
  default = []
}


#------------------------------------------------------------------------------
# NLB Inputs
#------------------------------------------------------------------------------
variable "nlb_access_logs_prefix_override" { default = null }
variable "nlb_access_logs_s3_bucket_id" { default = null }
variable "nlb_acm_certificate_arn" { default = null }
variable "nlb_deletion_protection_enabled" { default = false }
variable "nlb_subnet_ids" { default = [] }
variable "nlb_tls_ssl_policy" { default = "ELBSecurityPolicy-TLS13-1-2-2021-06" }


#------------------------------------------------------------------------------
# OpenVPN Inputs
#------------------------------------------------------------------------------
variable "openvpn_backup_schedule_expression" { default = "cron(0 00 00 ? * * *)" }
variable "openvpn_client_cidr_blocks" { default = ["172.27.0.0/16"] }
variable "openvpn_client_dhcp_network" { default = "172.27.32.0" }
variable "openvpn_client_dhcp_network_mask" { default = "20" }
variable "openvpn_client_static_addresses_enabled" { default = false }
variable "openvpn_client_static_network" { default = "172.27.64.0" }
variable "openvpn_client_static_network_mask" { default = "20" }
variable "openvpn_daemon_ingress_blocks" { default = ["0.0.0.0/0"] }
variable "openvpn_daemon_tcp_port" { default = 443 }
variable "openvpn_daemon_udp_port" { default = 1194 }
variable "openvpn_enable_mfa_delete" { default = false }
variable "openvpn_s3_access_logs_prefix_override" { default = null }
variable "openvpn_s3_access_logs_s3_bucket_id" { default = null }
variable "openvpn_s3_force_destroy" { default = true }
variable "openvpn_s3_lifecycle_configuration_rules" { default = [] }
variable "openvpn_s3_versioning_enabled" { default = true }
variable "openvpn_secret_admin_password_key" { default = "ADMIN_PASSWORD" }
variable "openvpn_secret_arn" { default = "" }
variable "openvpn_secret_enable_kms_key_rotation" { default = true }
variable "openvpn_secret_kms_key_arn" { default = null }
variable "openvpn_ssm_association_output_bucket_name" { default = null }
variable "openvpn_time_zone" { default = "America/Chicago" }
variable "openvpn_ui_https_port" { default = 943 }
variable "openvpn_ui_ingress_blocks" { default = ["0.0.0.0/0"] }
variable "openvpn_web_server_name" { default = "OpenVPN Server" }
variable "openvpn_s3_object_ownership" { default = "BucketOwnerEnforced" }
variable "openvpn_tls_version_min" { default = "1.2" }
variable "openvpn_enable_server_nat" { default = true }
variable "openvpn_s3_source_policy_documents" {
  type        = list(string)
  default     = []
  description = <<-EOT
    List of IAM policy documents that are merged together into the exported document.
    Statements defined in source_policy_documents must have unique SIDs.
    Statement having SIDs that match policy SIDs generated by this module will override them.
    EOT
}

variable "openvpn_version" {
  type    = string
  default = "2.11.1-f4027f58-Ubuntu22"
}
variable "ec2_additional_instance_role_policies" {
  type    = any
  default = []
}
