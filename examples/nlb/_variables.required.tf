

variable "openvpn_hostname" {
  type = string
}


variable "openvpn_dhcp_option_domain" {}
variable "subnet_ids" { type = list(string) }
variable "vpc_cidr_blocks" { type = list(string) }
variable "vpc_id" { type = string }
