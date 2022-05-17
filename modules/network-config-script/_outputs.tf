output "script_name" {
  value = one(aws_s3_object.network_sh[*].key)
}
