vpc_cidr_block     = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

# Need to set required variables from module, even though these are not supplied to the implementation
openvpn_dhcp_option_domain = ""
vpc_cidr_blocks            = [""]
vpc_id                     = ""
subnet_ids                 = [""]
openvpn_hostname           = ""
