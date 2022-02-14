output "ec2_security_group_id" {
  value = var.openvpn_security_group_id != null ? var.openvpn_security_group_id : module.ec2_asg_sg.id
}

output "ec2_role_arn" {
  value = module.ec2_asg_role.arn
}

output "ec2_role_name" {
  value = module.ec2_asg_role.name
}
