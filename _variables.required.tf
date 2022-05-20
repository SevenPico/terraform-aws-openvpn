

variable "openvpn_hostname" {
  type = string
}


variable "openvpn_dhcp_option_domain" {}
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



