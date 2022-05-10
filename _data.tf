
data "aws_region" "current" {
  count = module.this.enabled ? 1 : 0
}

data "aws_caller_identity" "current" {
  count = module.this.enabled ? 1 : 0
}


