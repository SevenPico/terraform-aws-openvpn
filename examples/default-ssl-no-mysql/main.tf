module "openvpn" {
  source  = "../.."
  context = module.this.context

  # Required
  openvpn_asg_ami_image_id          = "ami-06e31403ada2e8ff4"
  openvpn_public_hosted_zone_id     = data.aws_route53_zone.public[0].id
  openvpn_server_dhcp_option_domain = aws_route53_zone.private[0].name
  openvpn_vpc_cidr_block            = module.vpc.vpc_cidr_block
  openvpn_vpc_id                    = module.vpc.vpc_id
  openvpn_vpc_private_subnet_ids    = module.vpc_subnets.private_subnet_ids
  openvpn_vpc_public_subnet_ids     = module.vpc_subnets.public_subnet_ids
}
