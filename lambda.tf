##------------------------------------------------------------------------------
## Labels
##------------------------------------------------------------------------------
module "ssl_cert_updater_lambda_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  enabled    = module.context.enabled && var.enable_ssl_cert_updater
  attributes = ["lambda"]
}

module "ssl_cert_updater_lambda_role_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.ssl_cert_updater_lambda_context.self
  attributes = ["role"]
}


##------------------------------------------------------------------------------
## IAM Role
##------------------------------------------------------------------------------
data "aws_iam_policy_document" "ssl_cert_updater_lambda_policy" {
  count = module.ssl_cert_updater_lambda_role_context.enabled ? 1 : 0
  statement {
    sid    = "PermissionSSMDocuments"
    effect = "Allow"
    actions = ["ssm:DescribeDocument",
    "ssm:ExecuteDocument"]
    resources = [
      aws_ssm_document.configure_ssl[0].arn
    ]
  }
  statement {
    sid       = "DecryptSslKmsKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [var.ssl_secret_kms_key_arn]
  }
}


#------------------------------------------------------------------------------
# Lambda Artifact
#------------------------------------------------------------------------------
data "archive_file" "artifact" {
  count       = module.ssl_cert_updater_lambda_context.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/ssl-cert-updater-lambda/"
  output_path = "${path.module}/temp/lambda.zip"
}


#------------------------------------------------------------------------------
# Lambda Cloudwatch Log Group
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ssl_cert_updater_lambda_log_group" {
  count             = module.ssl_cert_updater_lambda_context.enabled ? 1 : 0
  name              = "/aws/lambda/${module.ssl_cert_updater_lambda_context.id}"
  retention_in_days = 30
  tags              = module.context.tags
}

#------------------------------------------------------------------------------
# Lambda Function
#------------------------------------------------------------------------------
module "ssl_updater_lambda_function" {
  source  = "registry.terraform.io/SevenPicoForks/lambda-function/aws"
  version = "2.0.1"
  context = module.ssl_cert_updater_lambda_context.self

  filename         = try(data.archive_file.artifact[0].output_path, "")
  source_code_hash = try(data.archive_file.artifact[0].output_base64sha256, "")
  function_name    = "${module.ssl_cert_updater_lambda_context.id}-ssl-updater"
  handler          = "app.lambda_handler"
  role_name        = "${module.ssl_cert_updater_lambda_role_context.id}-ssl-updater"
  runtime          = "python3.8"

  cloudwatch_logs_retention_in_days   = 30
  architectures                       = null
  cloudwatch_event_rules              = {}
  cloudwatch_lambda_insights_enabled  = false
  cloudwatch_log_subscription_filters = {}
  cloudwatch_logs_kms_key_arn         = null
  description                         = "Update SSL Certificate."
  event_source_mappings = {}
  ignore_external_function_updates    = false
  image_config                        = {}
  image_uri                           = null
  kms_key_arn                         = ""
  lambda_at_edge                      = false
  lambda_role_source_policy_documents = data.aws_iam_policy_document.ssl_cert_updater_lambda_policy[*].json
  layers                              = []
  memory_size                         = 128
  package_type                        = "Zip"
  publish                             = true
  reserved_concurrent_executions      = -1
  s3_bucket                           = null
  s3_key                              = null
  s3_object_version                   = null
  sns_subscriptions                   = {}
  ssm_parameter_names                 = null
  timeout                             = 3
  tracing_config_mode                 = null
  vpc_config                          = null

  lambda_environment = {
    variables = {
      SSM_DOCUMENT_HASH = try(aws_ssm_document.configure_ssl[0].name, "")
    }
  }
}


#------------------------------------------------------------------------------
# Lambda Function SSL Secrets Update Invocation Subscription
#------------------------------------------------------------------------------
resource "aws_lambda_permission" "ssl_certificate_updates" {
  count      = module.ssl_cert_updater_lambda_context.enabled ? 1 : 0
  depends_on = [module.ssl_updater_lambda_function]

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.ssl_updater_lambda_function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.ssl_certificate_sns_topic_arn
}

resource "aws_sns_topic_subscription" "ssl_updater_lambda_subscription" {
  count      = module.ssl_cert_updater_lambda_context.enabled ? 1 : 0
  depends_on = [aws_lambda_permission.ssl_certificate_updates]

  topic_arn = var.ssl_certificate_sns_topic_arn
  protocol  = "lambda"
  endpoint  = module.ssl_updater_lambda_function.arn
}
