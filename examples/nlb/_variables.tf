variable "vpc_cidr_block" { default = "10.10.0.0/16"}
variable "availability_zones" {default = ["us-east-1a", "us-east-1b", "us-east-1c"]}
variable "common_name" { }
variable "root_domain" { default = "7pi.io" }
