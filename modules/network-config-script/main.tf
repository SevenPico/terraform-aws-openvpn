module "network_sh_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.this.context
  attributes = ["network"]
}

resource "aws_s3_object" "network_sh" {
  count  = module.network_sh_meta.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = "network.sh"
  content = templatefile("${path.module}/network.sh.tftpl", {
    client_dhcp_network          = var.openvpn_client_dhcp_network,
    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    client_group_dhcp_cidr_block = var.openvpn_client_group_dhcp_cidr_block,
    client_static_network        = var.openvpn_client_static_network,
    client_static_network_mask   = var.openvpn_client_static_network_mask
  })
}
