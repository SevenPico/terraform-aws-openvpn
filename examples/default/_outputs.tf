output "autoscaling_group_arn" {
  value = module.openvpn.autoscale_group_arn
}

output "ec2_security_group_id" {
  value = module.openvpn.security_group_id
}

output "autoscaling_role_arn" {
  value = module.openvpn.role_arn
}

output "autoscaling_lifecycle_role_arn" {
  value = module.openvpn.lifecycle_role_arn
}

output "autoscaling_sns_role_arn" {
  value = module.openvpn.sns_role_arn
}


