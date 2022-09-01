#------------------------------------------------------------------------------
# VPC Meta
#------------------------------------------------------------------------------
module "vpc_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.context.self
  attributes = ["vpc"]
}

module "vpc_subnets_context" {
  source     = "app.terraform.io/SevenPico/context/null"
  version    = "1.0.2"
  context    = module.vpc_context.self
  attributes = ["subnet"]
}

module "vpc_endpoint_sg_context" {
  source  = "app.terraform.io/SevenPico/context/null"
  version = "1.0.2"
  context = module.context.self
  enabled = module.context.enabled && local.create_private_links
}


#------------------------------------------------------------------------------
# VPC Subnets
#------------------------------------------------------------------------------
module "vpc" {
  source  = "registry.terraform.io/cloudposse/vpc/aws"
  version = "0.28.1"
  context = module.vpc_context.self

  cidr_block                                      = var.vpc_cidr_block
  additional_cidr_blocks                          = []
  assign_generated_ipv6_cidr_block                = false
  classiclink_dns_support_enabled                 = false
  classiclink_enabled                             = false
  default_security_group_deny_all                 = true
  dns_hostnames_enabled                           = true
  dns_support_enabled                             = true
  enable_classiclink                              = false
  enable_default_security_group_with_custom_rules = false
  enable_classiclink_dns_support                  = false
  enable_dns_hostnames                            = true
  enable_dns_support                              = true
  enable_internet_gateway                         = true
  instance_tenancy                                = "default"
  internet_gateway_enabled                        = true
  ipv6_egress_only_internet_gateway_enabled       = false
  ipv6_enabled                                    = true
}


#------------------------------------------------------------------------------
# VPC Subnets
#------------------------------------------------------------------------------
module "vpc_subnets" {
  source  = "registry.terraform.io/cloudposse/dynamic-subnets/aws"
  version = "0.39.8"
  context = module.vpc_subnets_context.self

  availability_zones                   = var.availability_zones
  cidr_block                           = var.vpc_cidr_block
  igw_id                               = module.vpc.igw_id
  vpc_id                               = module.vpc.vpc_id
  availability_zone_attribute_style    = "short"
  aws_route_create_timeout             = "2m"
  aws_route_delete_timeout             = "2m"
  map_public_ip_on_launch              = true
  max_subnet_count                     = 0 // 0 means create 1 for each AZ
  metadata_http_endpoint_enabled       = false
  metadata_http_put_response_hop_limit = 1
  metadata_http_tokens_required        = true
  nat_elastic_ips                      = []
  nat_gateway_enabled                  = false
  nat_instance_enabled                 = false
  nat_instance_type                    = "t3.micro"
  private_network_acl_id               = ""
  private_subnets_additional_tags      = {}
  public_network_acl_id                = ""
  public_subnets_additional_tags       = {}
  root_block_device_encrypted          = true
  subnet_type_tag_key                  = "Type"
  subnet_type_tag_value_format         = "%s"
  vpc_default_route_table_id           = ""
}


#------------------------------------------------------------------------------
# VPC Endpoint Metadata
#------------------------------------------------------------------------------
locals {
  create_private_links = length(local.interface_vpc_endpoints) > 0 || length(local.gateway_vpc_endpoints) > 0
  interface_vpc_endpoints = {
    "ec2" : {
      private_dns_enabled = true
    }
    "ec2messages" : {
      private_dns_enabled = true
    }
    #    "ecs" : {
    #      private_dns_enabled = true
    #    }
    #    "logs" : {
    #      private_dns_enabled = true
    #    }
    #    "s3" : {
    #      private_dns_enabled = false
    #    }
    #    "secretsmanager" : {
    #      private_dns_enabled = true
    #    }
    #    "ecr.dkr" : {
    #      private_dns_enabled = true
    #    }
    #    "ecr.api" : {
    #      private_dns_enabled = true
    #    }
    "ssm" : {
      private_dns_enabled = true
    }
    "ssmmessages" : {
      private_dns_enabled = true
    }
    # "elasticfilesystem" : {
    #   private_dns_enabled = true
    # }
    # "codepipeline" : {
    #   private_dns_enabled = true
    #   policy = null
    # }
  }

  gateway_vpc_endpoints = [
    #    "s3",
    # "dynamodb",
  ]
}


#------------------------------------------------------------------------------
# VPC Endpoint Security Groups
#------------------------------------------------------------------------------
module "vpc_endpoint_sg" {
  source     = "registry.terraform.io/cloudposse/security-group/aws"
  version    = "0.4.2"
  context    = module.vpc_endpoint_sg_context.self
  attributes = ["vpc", "endpoint"]

  allow_all_egress              = false
  create_before_destroy         = false
  inline_rules_enabled          = false
  revoke_rules_on_delete        = false
  rule_matrix                   = []
  rules_map                     = {}
  security_group_create_timeout = "5m"
  security_group_delete_timeout = "5m"
  security_group_description    = "Allow access to Interface VPC Private Link Endpoint"
  security_group_name           = []
  target_security_group_id      = []

  vpc_id = module.vpc.vpc_id
  rules = [{
    description = "Security Group Rule for Interface VPC Private Link  Endpoint"
    type        = "ingress"
    protocol    = "TCP"
    cidr_blocks = [module.vpc.vpc_cidr_block]
    from_port   = 443
    to_port     = 443
    self        = null
  }]
}


#------------------------------------------------------------------------------
# VPC Endpoints
#------------------------------------------------------------------------------
module "vpc_endpoints" {
  source  = "registry.terraform.io/cloudposse/vpc/aws//modules/vpc-endpoints"
  version = "0.28.1"
  context = module.vpc_context.self
  enabled = module.vpc_context.enabled && local.create_private_links

  vpc_id = module.vpc.vpc_id


  gateway_vpc_endpoints = {
    for key in local.gateway_vpc_endpoints :
    key => {
      name = key
      policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "*"
          Principal = "*"
          Resource  = "*"
        }]
      })
    }
  }

  interface_vpc_endpoints = {
    for key, value in local.interface_vpc_endpoints :
    key => {
      name                = key
      subnet_ids          = module.vpc_subnets.private_subnet_ids
      security_group_ids  = [module.vpc_endpoint_sg.id]
      private_dns_enabled = value["private_dns_enabled"]
      policy = lookup(value, "policy", jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "*"
          Principal = "*"
          Resource  = "*"
        }]
      }))
    }
  }
}

resource "aws_vpc_endpoint_route_table_association" "vpc_gateway_endpoint" {
  count           = module.vpc_context.enabled && length(module.vpc_endpoints.gateway_vpc_endpoints) > 0 ? length(var.availability_zones) : 0
  route_table_id  = module.vpc_subnets.private_route_table_ids[count.index]
  vpc_endpoint_id = module.vpc_endpoints.gateway_vpc_endpoints[0].id
}
