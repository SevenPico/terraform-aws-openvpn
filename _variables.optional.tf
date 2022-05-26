
variable "ec2_user_data" {
  type = string
  default = ""
}

variable "openvpn_nlb_target_groups" {
  type = list(string)
  default = []
}
variable "openvpn_ui_ingress_blocks" {
  type = list(string)
  default = ["0.0.0.0/0"]
}
variable "openvpn_daemon_ingress_blocks" {
  type = list(string)
  default = ["0.0.0.0/0"]
}
variable "openvpn_config_scripts" {
  type = list(string)
  default = [
    "init.sh",
    "openvpn.sh"
  ]
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

variable "openvpn_client_cidr_blocks" { default = ["172.27.0.0/16"] }

variable "cloudwatch_logs_expiration_days" { default = 90 }
variable "logs_storage_bucket_id" { default = null }
variable "logs_storage_versioning_enabled" { default = true }
variable "logs_storage_versioning_mfa_delete_enabled" { default = false }
variable "logs_storage_lifecycle_rule_enabled" { default = true }
variable "logs_storage_force_destroy" { default = true }
variable "logs_storage_enable_noncurrent_version_expiration" { default = true }
variable "logs_storage_noncurrent_version_expiration_days" { default = 90 }
variable "logs_storage_noncurrent_version_transition_days" { default = 30 }
variable "logs_storage_standard_transition_days" { default = 30 }
variable "logs_storage_glacier_transition_days" { default = 60 }
variable "logs_storage_enable_glacier_transition" { default = true }
variable "logs_storage_expiration_days" { default = 90 }
variable "logs_storage_abort_incomplete_multipart_upload_days" { default = 5 }
