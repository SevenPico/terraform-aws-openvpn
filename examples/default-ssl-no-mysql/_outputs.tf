output "ec2_security_group_id" {
  value = module.openvpn.ec2_security_group_id
}

output "ec2_role_arn" {
  value = module.openvpn.ec2_role_arn
}

output "ec2_role_name" {
  value = module.openvpn.ec2_role_name
}

output "autoscaling_group_arn" {
  value = module.openvpn.autoscaling_group_arn
}
