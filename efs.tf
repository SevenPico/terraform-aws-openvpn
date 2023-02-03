module "efs" {
  source     = "registry.terraform.io/cloudposse/efs/aws"
  version    = "0.32.7"
  context    = module.ec2_autoscale_group_context.self
  enabled    = var.efs_enabled && module.ec2_autoscale_group_context.enabled
  attributes = ["efs"]

  access_points = {
    "config" = {
      posix_user = {
        gid = "1000"
        uid = "1000"
      }
      creation_info = {
        gid         = "1000"
        uid         = "1000"
        permissions = "0777"
      }
    }
  }

  additional_security_group_rules      = []
  allowed_cidr_blocks                  = []
  allowed_security_group_ids           = [module.ec2_autoscale_group_sg.id]
  associated_security_group_ids        = []
  availability_zone_name               = null
  create_security_group                = true
  dns_name                             = ""
  efs_backup_policy_enabled            = false
  encrypted                            = true
  kms_key_id                           = null
  mount_target_ip_address              = null
  performance_mode                     = "generalPurpose"
  provisioned_throughput_in_mibps      = 0
  region                               = data.aws_region.current.name
  security_group_create_before_destroy = true
  security_group_create_timeout        = "10m"
  security_group_delete_timeout        = "15m"
  security_group_description           = "EFS Security Group"
  security_group_name                  = []
  security_groups                      = []
  subnets                              = var.subnet_ids
  throughput_mode                      = "bursting"
  transition_to_ia                     = ["AFTER_30_DAYS"]
  transition_to_primary_storage_class  = []
  vpc_id                               = var.vpc_id
  zone_id                              = []
}
