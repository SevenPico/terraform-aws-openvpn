variable "vpc_cidr_block" { default = "10.10.0.0/16" }
variable "availability_zones" { default = ["us-east-1a", "us-east-1b", "us-east-1c"] }
variable "common_name" {}
variable "root_domain" { default = "7pi.io" }

variable "openvpn_client_dhcp_network" { default = "172.27.0.0" }
variable "openvpn_client_dhcp_network_mask" { default = "20" }
variable "openvpn_client_group_dhcp_cidr_block" { default = "172.27.16.0/20" }
variable "openvpn_client_static_network" { default = "172.27.32.0" }
variable "openvpn_client_static_network_mask" { default = "20" }

variable "rds_admin_username" { default = "admin" }
variable "rds_admin_password" { default = "changeme" }
variable "rds_port" { default = 3306 }


