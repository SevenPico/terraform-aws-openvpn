module "ec2_autoscale_group_ssm_initialization_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.ec2_autoscale_group_meta.context
  attributes = ["initialization"]
}

module "ec2_autoscale_group_ssm_ssl_certificate_refresh_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.ec2_autoscale_group_meta.context
  attributes = ["ssl", "certificate", "refresh"]
}

#------------------------------------------------------------------------------
# EC2 VPN SSM Document for VPN Initialization
#------------------------------------------------------------------------------
#locals {
#  openvpn_config_script_commands = length(var.openvpn_config_scripts) > 0 ? join(" && ", [for x in var.openvpn_config_scripts : "sudo ./${x}"]) : ""
#}

resource "aws_ssm_document" "ec2_autoscale_group_initialization" {
  count           = module.ec2_autoscale_group_meta.enabled ? 1 : 0
  name            = module.ec2_autoscale_group_ssm_initialization_meta.id
  document_format = "JSON"
  document_type   = "Command"

  tags = module.ec2_autoscale_group_ssm_initialization_meta.tags
  content = templatefile("${path.module}/scripts/ssm-init.tftpl", {
    environment       = module.ec2_autoscale_group_ssm_initialization_meta.environment
    scripts_bucket_id = module.ec2_autoscale_group_scripts_bucket.bucket_id
    region            = data.aws_region.current[0].name
    config_cmds       = var.openvpn_config_scripts
  })

  #  content = <<DOC
  #{
  #  "schemaVersion": "2.2",
  #  "description": "Bootstraps the OpenVPN Marketplace AMI",
  #  "parameters": {
  #    "Environment": {
  #      "description": "The Environment The Server is running in.",
  #      "type": "String",
  #      "default": "${module.ec2_autoscale_group_ssm_initialization_meta.environment}"
  #    }
  #  },
  #  "mainSteps": [
  #    {
  #      "action": "aws:runShellScript",
  #      "name": "VpnInitializion",
  #      "inputs": {
  #        "runCommand": [
  #          "#!/bin/bash",
  #          "DEBIAN_FRONTEND=noninteractive",
  #          "sudo rm /var/lib/dpkg/lock > /dev/null 2>&1",
  #          "sudo rm /var/lib/dpkg/lock-frontend > /dev/null 2>&1",
  #          "sudo apt-get update -y -q",
  #          "sudo apt-get install ntp -y -q",
  #          "sudo apt-get install jq -y -q",
  #          "sudo apt-get install awscli -y -q",
  #          "sudo apt-get install libmariadb3 -y -q",
  #          "sudo apt-get install mariadb-client-core-10.1 -y -q",
  #          "cd /root",
  #          "mkdir -p ./scripts",
  #          "sudo aws s3 sync s3://${module.ec2_autoscale_group_scripts_bucket.bucket_id} ./scripts/ --region ${data.aws_region.current[0].name} --delete --sse",
  #          "cd ./scripts",
  #          "sudo chmod o-rwx *.sh",
  #          "sudo chmod ug+rwx *.sh",
  #          "${local.openvpn_config_script_commands}"
  #        ]
  #      }
  #    }
  #  ]
  #}
  #DOC
}

resource "aws_ssm_association" "ec2_autoscale_group_initialization" {
  count            = module.ec2_autoscale_group_meta.enabled ? 1 : 0
  association_name = module.ec2_autoscale_group_ssm_initialization_meta.id
  name             = aws_ssm_document.ec2_autoscale_group_initialization[0].name
  targets {
    key    = "tag:Name"
    values = [module.ec2_autoscale_group_meta.id]
  }
}
