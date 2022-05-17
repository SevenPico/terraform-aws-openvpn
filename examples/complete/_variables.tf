variable "vpc_cidr_block" {}
variable "availability_zones" {}
variable "common_name" {}
variable "root_domain" { default = "sevenpico.com" }

variable "rds_admin_username" {}
variable "rds_admin_password" {}
variable "rds_port" {}


variable "openvpn_client_dhcp_network" { default = "172.27.0.0" }
variable "openvpn_client_dhcp_network_mask" { default = "20" }
variable "openvpn_client_group_dhcp_cidr_block" { default = "172.27.16.0/20" }
variable "openvpn_client_static_network" { default = "172.27.32.0" }
variable "openvpn_client_static_network_mask" { default = "20" }

