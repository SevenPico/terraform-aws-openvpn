module "reverse_routing_sh_meta" {
  source     = "registry.terraform.io/cloudposse/label/null"
  version    = "0.25.0"
  context    = module.this.context
  attributes = ["reverse-routing"]
}

resource "aws_s3_object" "reverse_routing_sh" {
  count  = module.reverse_routing_sh_meta.enabled ? 1 : 0
  bucket = var.bucket_id
  key    = "reverse-routing.sh"
  content = templatefile("${path.module}/reverse-routing.sh.tftpl", {
#    client_dhcp_network          = var.openvpn_client_dhcp_network,
#    client_dhcp_network_mask     = var.openvpn_client_dhcp_network_mask,
    openvpn_client_cidr_blocks   = join(" ", var.openvpn_client_cidr_blocks),
    vpc_cidr_blocks              = join(" ", var.vpc_cidr_blocks)
  })
}
