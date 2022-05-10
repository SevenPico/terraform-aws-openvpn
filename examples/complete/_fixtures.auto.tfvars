vpc_cidr_block     = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
common_name        = "sevenpico.com"

ami_id = "ami-037ff6453f0855c46"

ssl_certificate_enabled = true

rds_use_mysql_backend = true
rds_admin_username    = "admin"
rds_admin_password    = "CHANGE_ME_NOW_PLEASE"
rds_port              = 3306



# Need to set required variables from module, even though these are not supplied to the implementation
openvpn_dhcp_option_domain = ""
private_hosted_zone_id = ""
private_subnet_ids = [""]
public_hosted_zone_id = ""
public_subnet_ids = [""]
vpc_cidr_blocks = [""]
vpc_id = ""
