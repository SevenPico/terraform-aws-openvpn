variable "bucket_id" { type = string }
variable "script_name" { type = string }
variable "ec2_role_name" { type = string }

variable "secrets_arn" { type = string }
variable "secrets_kms_key_arn" { type = string }
variable "secrets_licence_keyname" {
  default = "OPENVPN_LICENSE"
  type    = string
}
