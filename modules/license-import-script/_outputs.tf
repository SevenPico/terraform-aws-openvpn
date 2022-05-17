output "script_name" {
  value = one(aws_s3_object.this[*].key)
}
