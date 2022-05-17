variable "bucket_id" { type = string }
variable "script_name" { type = string }
variable "ec2_role_name" { type = string }

variable "ssl_secret_arn" { type = string }
variable "ssl_secret_kms_key_arn" { type = string }
variable "ssl_secret_certificate_bundle_keyname" { default = "CERTIFICATE_CHAIN" }
variable "ssl_secret_certificate_keyname" { default = "CERTIFICATE" }
variable "ssl_secret_certificate_private_key_keyname" { default = "CERTIFICATE_PRIVATE_KEY" }
