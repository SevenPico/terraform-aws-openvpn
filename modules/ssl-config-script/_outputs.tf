output "script_name" {
  value = one(aws_s3_object.ssl_cert_sh[*].key)
}
