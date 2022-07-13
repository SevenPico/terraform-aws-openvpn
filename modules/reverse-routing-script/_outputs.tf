output "script_name" {
  value = one(aws_s3_object.reverse_routing_sh[*].key)
}
