#------------------------------------------------------------------------------
# Labels
#------------------------------------------------------------------------------
module "lambda_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.context.self
  attributes = ["lambda"]
}

module "lambda_role_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.lambda_context.self
  attributes = ["role"]
}

module "sg_context" {
  source     = "registry.terraform.io/SevenPico/context/null"
  version    = "2.0.0"
  context    = module.lambda_context.self
  attributes = ["sg"]
}


#------------------------------------------------------------------------------
# IAM Role
#------------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume_role" {
  count = module.lambda_role_context.enabled ? 1 : 0
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "this" {
  #checkov:skip=CKV_AWS_356:skipping 'Ensure no IAM policies documents allow "*" as a statement's resource for restrictable actions'
  #checkov:skip=CKV_AWS_111:skipping 'Ensure IAM policies does not allow write access without constraints'
  count = module.lambda_role_context.enabled ? 1 : 0
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = [aws_cloudwatch_log_group.this[0].arn]
  }
  statement {
    actions = [
      "autoscaling:DescribeTags",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:CompleteLifecycleAction"
    ]
    effect    = "Allow"
    resources = [var.autoscale_group_arn]
  }
  statement {
    actions = [
      "ec2:DescribeRouteTables",
      "ec2:ModifyInstanceAttribute"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
  statement {
    actions = [
      "ec2:CreateRoute",
      "ec2:ReplaceRoute",
      "ec2:DeleteRoute"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ec2:*:*:route-table/*",
    ]
  }
}

data "aws_iam_policy_document" "sns" {
  count = module.lambda_role_context.enabled && var.results_sns_arn != null ? 1 : 0
  statement {
    actions = [
      "sns:Publish"
    ]
    effect = "Allow"
    resources = [
      var.results_sns_arn
    ]
  }
}

resource "aws_iam_role" "this" {
  count              = module.lambda_role_context.enabled ? 1 : 0
  name               = module.lambda_role_context.id
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json
  tags               = module.context.tags
  description        = "Lambda permissions to perform VPC Route Table updates."
}

resource "aws_iam_role_policy" "this" {
  count  = module.lambda_role_context.enabled ? 1 : 0
  name   = "${module.lambda_role_context.id}-policy"
  role   = aws_iam_role.this[0].name
  policy = data.aws_iam_policy_document.this[0].json
}

resource "aws_iam_role_policy" "this_sns" {
  count  = module.lambda_role_context.enabled && var.results_sns_arn != null ? 1 : 0
  name   = "${module.lambda_role_context.id}-sns-policy"
  role   = aws_iam_role.this[0].name
  policy = data.aws_iam_policy_document.sns[0].json
}

resource "aws_iam_role_policy_attachment" "this" {
  count      = module.lambda_role_context.enabled ? 1 : 0
  role       = aws_iam_role.this[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


#------------------------------------------------------------------------------
# Lambda Artifact
#------------------------------------------------------------------------------
#module "artifact" {
#  source      = "registry.terraform.io/cloudposse/module-artifact/external"
#  version     = "0.7.1"
#  enabled     = module.context.enabled
#  filename    = "lambda.zip"
#  module_name = "terraform-aws-lambda-elasticsearch-cleanup"
#  module_path = path.module
#  git_ref     = var.artifact_git_ref
#  url         = var.artifact_url
#}

data "archive_file" "artifact" {
  count       = module.lambda_context.enabled ? 1 : 0
  type        = "zip"
  source_dir  = "${path.module}/lambda-src/"
  output_path = "${path.module}/temp/lambda.zip"
}


#------------------------------------------------------------------------------
# Lambda Cloudwatch Log Group
#------------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158:skipping 'Ensure that CloudWatch Log Group is encrypted by KMS'
  #checkov:skip=CKV_AWS_338:skipping 'Ensure CloudWatch log groups retains logs for at least 1 year'
  count             = module.lambda_context.enabled ? 1 : 0
  name              = "/aws/lambda/${module.lambda_context.id}"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = module.context.tags
}

#------------------------------------------------------------------------------
# Lambda Function
#------------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  #checkov:skip=CKV_AWS_173:skipping 'Check encryption settings for Lambda environmental variable'
  #checkov:skip=CKV_AWS_50:skipping 'X-ray tracing is enabled for Lambda'
  #checkov:skip=CKV_AWS_117:skipping 'Ensure that AWS Lambda function is configured inside a VPC'
  #checkov:skip=CKV_AWS_116:skipping 'Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)'
  #checkov:skip=CKV_AWS_272:skipping 'Ensure AWS Lambda function is configured to validate code-signing'
  count                          = module.lambda_context.enabled ? 1 : 0
  filename                       = data.archive_file.artifact[0].output_path
  function_name                  = module.lambda_context.id
  description                    = "Update VPC Route Tables with routes to EC2 instances in the associated Autoscale Group."
  timeout                        = var.lambda_timeout
  runtime                        = var.lambda_runtime
  role                           = aws_iam_role.this[0].arn
  handler                        = "app.lambda_handler"
  reserved_concurrent_executions = var.reserved_concurrent_executions
  source_code_hash               = data.archive_file.artifact[0].output_base64sha256
  tags                           = module.lambda_context.tags
  layers = [
    "arn:aws:lambda:${data.aws_region.current.name}:017000801446:layer:AWSLambdaPowertoolsPython:19"
  ]

  dynamic "environment" {
    for_each = var.lambda_environment_variables_map != {} ? [1] : []
    content {
      variables = merge({
        LOG_LEVEL           = var.lambda_log_level
        VPC_ID              = var.vpc_id
        CIDR_BLOCK_TO_ROUTE = var.cidr_block_to_route
        },
      var.lambda_environment_variables_map)
    }
  }
}


#------------------------------------------------------------------------------
# Lambda Function SNS Invocation Subscription
#------------------------------------------------------------------------------
resource "aws_lambda_permission" "this" {
  count      = module.lambda_context.enabled ? 1 : 0
  depends_on = [aws_lambda_function.this]

  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this[0].arn
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_source_topic_arn
}

resource "aws_sns_topic_subscription" "this" {
  count      = module.lambda_context.enabled ? 1 : 0
  depends_on = [aws_lambda_permission.this]

  topic_arn = var.sns_source_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.this[0].arn
}
