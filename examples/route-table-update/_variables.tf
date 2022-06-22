variable "vpc_cidr_block" {}
variable "availability_zones" {}
variable "common_name" {}
variable "root_domain" { default = "sevenpico.com" }
variable "cidr_block_to_route" {
  type = string
}


