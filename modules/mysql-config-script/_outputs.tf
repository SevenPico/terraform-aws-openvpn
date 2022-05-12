output "script_name" {
  value = one(aws_s3_object.openvpn_init_mysql_script[*].key)
}
