## ----------------------------------------------------------------------------
##  Copyright 2023 SevenPico, Inc.
##
##  Licensed under the Apache License, Version 2.0 (the "License");
##  you may not use this file except in compliance with the License.
##  You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
##  Unless required by applicable law or agreed to in writing, software
##  distributed under the License is distributed on an "AS IS" BASIS,
##  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
##  See the License for the specific language governing permissions and
##  limitations under the License.
## ----------------------------------------------------------------------------

## ----------------------------------------------------------------------------
##  ./examples/default/vpc.tf
##  This file contains code written by SevenPico, Inc.
## ----------------------------------------------------------------------------

module "vpc_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["vpc"]
}

module "vpc_subnets_context" {
  source     = "SevenPico/context/null"
  version    = "2.0.0"
  context    = module.vpc_context.self
  attributes = ["subnet"]
}


#------------------------------------------------------------------------------
# VPC Subnets
#------------------------------------------------------------------------------
module "vpc" {
  source  = "registry.terraform.io/SevenPico/vpc/aws"
  version = "3.0.1"
  context = module.vpc_context.self

  assign_generated_ipv6_cidr_block          = false
  default_network_acl_deny_all              = false
  default_route_table_no_routes             = false
  default_security_group_deny_all           = true
  dns_hostnames_enabled                     = true
  dns_support_enabled                       = true
  instance_tenancy                          = "default"
  internet_gateway_enabled                  = true
  ipv4_additional_cidr_block_associations   = {}
  ipv4_cidr_block_association_timeouts      = null
  ipv4_primary_cidr_block                   = var.vpc_cidr_block
  ipv4_primary_cidr_block_association       = null
  ipv6_additional_cidr_block_associations   = {}
  ipv6_cidr_block_association_timeouts      = null
  ipv6_cidr_block_network_border_group      = null
  ipv6_egress_only_internet_gateway_enabled = false
  ipv6_primary_cidr_block_association       = null
}


#------------------------------------------------------------------------------
# VPC Subnets
#------------------------------------------------------------------------------
module "vpc_subnets" {
  source  = "SevenPico/dynamic-subnets/aws" # "registry.terraform.io/SevenPico/dynamic-subnets/aws"
  version = "3.0.1"
  context = module.vpc_subnets_context.self

  availability_zone_attribute_style        = "short"
  availability_zone_ids                    = []
  availability_zones                       = var.availability_zones
  aws_route_create_timeout                 = "2m"
  aws_route_delete_timeout                 = "2m"
  igw_id                                   = [module.vpc.igw_id]
  ipv4_cidr_block                          = [var.vpc_cidr_block]
  ipv4_cidrs                               = []
  ipv4_enabled                             = true
  ipv4_private_instance_hostname_type      = "ip-name"
  ipv4_private_instance_hostnames_enabled  = false
  ipv4_public_instance_hostname_type       = "ip-name"
  ipv4_public_instance_hostnames_enabled   = false
  ipv6_cidr_block                          = []
  ipv6_cidrs                               = []
  ipv6_egress_only_igw_id                  = []
  ipv6_enabled                             = false
  ipv6_private_instance_hostnames_enabled  = false
  ipv6_public_instance_hostnames_enabled   = false
  map_public_ip_on_launch                  = true
  max_nats                                 = 1
  max_subnet_count                         = 1 // 0 means create 1 for each AZ
  metadata_http_endpoint_enabled           = false
  metadata_http_put_response_hop_limit     = 1
  metadata_http_tokens_required            = true
  nat_elastic_ips                          = []
  nat_gateway_enabled                      = true
  nat_instance_ami_id                      = []
  nat_instance_cpu_credits_override        = ""
  nat_instance_root_block_device_encrypted = true
  nat_instance_type                        = "t3.micro"
  open_network_acl_ipv4_rule_number        = 100
  open_network_acl_ipv6_rule_number        = 111
  outpost_arn                              = null
  private_assign_ipv6_address_on_creation  = true
  private_dns64_nat64_enabled              = null
  private_label                            = "private"
  private_open_network_acl_enabled         = true
  private_route_table_enabled              = true
  private_subnets_enabled                  = true
  public_assign_ipv6_address_on_creation   = true
  public_dns64_nat64_enabled               = false
  public_label                             = "public"
  public_open_network_acl_enabled          = true
  public_route_table_enabled               = true
  public_route_table_ids                   = []
  public_route_table_per_subnet_enabled    = null
  public_subnets_additional_tags           = {}
  public_subnets_enabled                   = true
  root_block_device_encrypted              = true
  route_create_timeout                     = "5m"
  route_delete_timeout                     = "10m"
  subnet_create_timeout                    = "10m"
  subnet_delete_timeout                    = "10m"
  subnet_type_tag_key                      = "Type"
  subnet_type_tag_value_format             = "%s"
  subnets_per_az_count                     = 1
  subnets_per_az_names                     = ["common"]
  vpc_id                                   = module.vpc.vpc_id
  private_subnets_additional_tags          = {}
  nat_instance_enabled                     = false
}
