module "route_table_update" {
  source  = "../../"
  context = module.this.context

  autoscale_group_arn              = module.openvpn.autoscale_group_arn
  sns_source_topic_arn             = module.openvpn.autoscale_sns_topic_arn
  subnet_ids                       = module.vpc_subnets.private_subnet_ids
  vpc_id                           = module.vpc.vpc_id
  lambda_log_level                 = "DEBUG"
  cidr_block_to_route              = var.cidr_block_to_route
  artifact_git_ref                 = ""
  artifact_url                     = ""
  cloudwatch_log_retention_days    = 1
  lambda_runtime                   = "python3.9"
  lambda_timeout                   = 300
  results_sns_arn                  = null
  lambda_environment_variables_map = {}
}

resource "null_resource" "openvpn_set_autoscale_counts" {
  provisioner "local-exec" {
    command = join(" ", [
      "aws", "autoscaling", "update-auto-scaling-group",
      "--auto-scaling-group-name", module.openvpn.autoscale_group_name,
      "--desired-capacity", 1
    ])
  }

  depends_on = [
    module.openvpn,
    module.route_table_update,
  ]
}

resource "aws_security_group_rule" "this" {
  count                    = module.this.enabled ? 1 : 0
  security_group_id        = module.route_table_update.security_group_id
  protocol                 = "tcp"
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  source_security_group_id = join("", aws_security_group.vpc_endpoint_ec2_sg.*.id)
  description              = "Allow access to VPC Endpoints"
}


#------------------------------------------------------------------------------
# Private Link
#------------------------------------------------------------------------------
module "vpc_endpoints_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpc_meta.context
  attributes = ["endpoints"]
}

module "vpc_endpoints" {
  source  = "registry.terraform.io/cloudposse/vpc/aws//modules/vpc-endpoints"
  version = "0.28.1"
  context = module.vpc_endpoints_meta.context

  vpc_id                = module.vpc.vpc_id
  gateway_vpc_endpoints = {}
  interface_vpc_endpoints = {
    "ec2" = {
      name                = "ec2"
      security_group_ids  = aws_security_group.vpc_endpoint_ec2_sg.*.id
      subnet_ids          = module.vpc_subnets.private_subnet_ids
      policy              = null
      private_dns_enabled = true
    }
  }
}

module "vpc_endpoint_ec2_sg_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.vpc_endpoints_meta.context
  attributes = ["sg"]
}

resource "aws_security_group" "vpc_endpoint_ec2_sg" {
  count = module.vpc_endpoints_meta.enabled ? 1 : 0
  name = module.vpc_endpoint_ec2_sg_meta.id
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 443
    protocol    = "TCP"
    to_port     = 443
    cidr_blocks = [module.vpc.vpc_cidr_block]
    description = "Security Group for EC2 Interface VPC Endpoint"
  }
  tags = module.vpc_endpoint_ec2_sg_meta.tags
}

