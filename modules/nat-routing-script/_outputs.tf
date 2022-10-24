output "script_name" {
  value = one(aws_s3_object.nat_routing_sh[*].key)
}
