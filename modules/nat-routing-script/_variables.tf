variable "bucket_id" { type = string }
variable "script_name" { type = string }
variable "ec2_role_name" { type = string }

variable "openvpn_client_cidr_blocks" { type = list(string) }
variable "vpc_cidr_blocks" { type = list(string) }

