variable "bucket_id" { type = string }
variable "script_name" { type = string }
variable "ec2_role_name" { type = string }


variable "openvpn_client_dhcp_network" { type = string }
variable "openvpn_client_dhcp_network_mask" { type = number }
variable "openvpn_client_group_dhcp_cidr_block" { type = string }
variable "openvpn_client_static_network" { type = string }
variable "openvpn_client_static_network_mask" { type = number }

