output "ec2_security_group_id" {
  value = module.asg_ec2_openvpn_sg.id
}

output "ec2_role_arn" {
  value = module.ec2_openvpn_asg_role.arn
}

output "ec2_role_name" {
  value = module.ec2_openvpn_asg_role.name
}
