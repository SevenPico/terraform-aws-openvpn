resource "aws_cloudwatch_event_rule" "ssl_secrets" {
  name        = "secret_changes_rule"
  description = "A CloudWatch Events rule for secret changes"

  event_pattern = jsonencode({
    source      = ["aws.secretsmanager"]
    detail_type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["secretsmanager.amazonaws.com"]
      eventName = [
        "CreateSecret",
        "UpdateSecret",
        "DeleteSecret",
        "PutSecretValue",
        "RestoreSecret",
        "RotateSecret",
        "StopReplicationToReplica",
        "TagResource",
        "UntagResource",
      ]
      requestParameters = {
        arn = [module.ssl_certificate.secret_arn]
      }
    }
  })

  tags = {
    Environment = "production"
  }
}

resource "aws_sns_topic_subscription" "ssl_secrets_sns_subscription" {
  topic_arn = module.openvpn.autoscale_sns_topic_arn
  protocol  = "email"
  endpoint  = "ahiwrale@sigmasolve.net"
}

resource "aws_cloudwatch_event_target" "ssl_secrets_sns_subscription" {
  rule      = aws_cloudwatch_event_rule.ssl_secrets.name
  arn       = module.openvpn.autoscale_sns_topic_arn
  target_id = "secret_changes_target"

  depends_on = [
    aws_sns_topic_subscription.ssl_secrets_sns_subscription,
  ]
}