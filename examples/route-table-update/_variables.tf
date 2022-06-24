variable "vpc_cidr_block" {}
variable "availability_zones" {}
variable "common_name" {}
variable "root_domain" { default = "7pi.io" }
variable "cidr_block_to_route" {
  type = string
}


