
variable "ec2_user_data" {
  type = string
  default = ""
}

variable "openvpn_hostname" {
  type = string
}

variable "openvpn_ui_alb_target_groups" {
  type = list(string)
  default = []
}
variable "openvpn_ui_alb_https_port" {
  type = number
  default = 443
}
variable "openvpn_ui_alb_security_group_id" {
  type = string
  default = ""
}
variable "openvpn_daemon_nlb_target_groups" {
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

# Required
variable "openvpn_dhcp_option_domain" {}
#variable "private_hosted_zone_id" {}
#variable "private_subnet_ids" { type = list(string) }
#variable "public_hosted_zone_id" {}
variable "subnet_ids" { type = list(string) }
variable "vpc_cidr_blocks" { type = list(string) }
variable "vpc_id" { type = string }
variable "additional_secrets_map" {
  type = map(string)
  default = {
    OPENVPN_LICENSE: ""
  }
  description = "Specify additional information in the created SecretsManager document for OpenVPN.  These keys can be accessed by additional scripts added via the submodules."
}


# Optional
variable "ami_id" { default = "ami-037ff6453f0855c46" } # "This module was built using ami-037ff6453f0855c46 which is a BYOL, but supports 2 free connections."
variable "autoscale_desired_count" { default = 1 }
variable "autoscale_instance_type" { default = "t3.micro" }
variable "autoscale_max_count" { default = 1 }
variable "autoscale_min_count" { default = 1 }
variable "create_autoscale_sns_topic" { default = false }

#variable "openvpn_cluster_port" { default = 945 }
variable "openvpn_daemon_tcp_port" { default = 443 }
variable "openvpn_daemon_udp_port" { default = 1194 }
variable "openvpn_license_filepath" { default = null }
variable "openvpn_timezone" { default = "America/Chicago" }
variable "openvpn_ui_https_port" { default = 943 }
variable "openvpn_web_server_name" { default = "OpenVPN Server" }

variable "openvpn_client_cidr_blocks" { default = ["172.27.0.0/16"] }
#variable "openvpn_client_dhcp_network" { default = "172.27.0.0" }
#variable "openvpn_client_dhcp_network_mask" { default = "20" }
#variable "openvpn_client_group_dhcp_cidr_block" { default = "172.27.16.0/20" }
#variable "openvpn_client_static_network" { default = "172.27.32.0" }
#variable "openvpn_client_static_network_mask" { default = "20" }

#variable "openvpn_groups" {
#  type = list(object({
#    name            = string
#    c2s_dest_s      = bool
#    c2s_dest_v      = bool
#    group_declare   = bool
#    group_subnets-0 = string
#    prop_autologin  = bool
#    prop_deny       = bool
#    prop_superuser  = bool
#    type            = string
#  }))
#  default = [
#    {
#      name            = "Admin Users"
#      c2s_dest_s      = false
#      c2s_dest_v      = false
#      group_declare   = true
#      group_subnets-0 = ""
#      prop_autologin  = true
#      prop_deny       = false
#      prop_superuser  = true
#      type            = "group"
#    },
#    {
#      name            = "Organization Users"
#      c2s_dest_s      = false
#      c2s_dest_v      = false
#      group_declare   = true
#      group_subnets-0 = ""
#      prop_autologin  = false
#      prop_deny       = false
#      prop_superuser  = false
#      type            = "group"
#    }
#  ]
#}
#variable "openvpn_users" {
#  type = list(object({
#    name           = string
#    access_from-0  = string
#    access_from-1  = string
#    conn_ip        = string
#    conn_group     = string
#    prop_superuser = bool
#    prop_superuser = bool
#    type           = string
#  }))
#  default = [
#    {
#      name           = "openvpn"
#      access_from-0  = "+ALL_S2C_SUBNETS"
#      access_from-1  = "+ALL_VPN_CLIENTS"
#      conn_ip        = ""
#      conn_group     = "Admin Users"
#      prop_superuser = true
#      prop_autologin = false
#      type           = "user_compile"
#    }
#  ]
#}

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
