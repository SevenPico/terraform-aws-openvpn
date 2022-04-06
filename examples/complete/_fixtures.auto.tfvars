vpc_cidr_block     = "10.10.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
common_name        = "sevenpico.com"

ssl_certificate_enabled = true

rds_use_mysql_backend = true
rds_admin_username    = "admin"
rds_admin_password    = "CHANGE_ME_NOW_PLEASE"
rds_port              = 3306

