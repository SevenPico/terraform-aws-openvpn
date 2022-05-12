variable "bucket_id" { type = string }
variable "script_name" { type = string }
variable "ec2_role_name" { type = string }
variable "rds_mysql_instance_address" { type = string }
variable "rds_secret_arn" { type = string }
variable "rds_security_group_id" { type = string }
variable "rds_secret_kms_key_arn" { type = string }
variable "rds_secret_admin_password_keyname" { default = "ADMIN_PASSWORD" }
variable "rds_secret_admin_username_keyname" { default = "ADMIN_USERNAME" }
variable "rds_secret_port_keyname" { default = "PORT" }

