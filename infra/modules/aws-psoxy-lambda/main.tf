# provision a Psoxy instance into AWS account

terraform {
  required_providers {
    aws = {
      version = "~> 4.12"
    }
  }
}

resource "aws_lambda_function" "psoxy-instance" {
  function_name                  = var.function_name
  role                           = aws_iam_role.iam_for_lambda.arn
  architectures                  = ["arm64"] # 20% cheaper per ms exec time than x86_64
  runtime                        = "java11"
  filename                       = var.path_to_function_zip
  source_code_hash               = var.function_zip_hash
  handler                        = var.handler_class
  timeout                        = var.timeout_seconds
  memory_size                    = var.memory_size_mb
  reserved_concurrent_executions = coalesce(var.reserved_concurrent_executions, -1)

  environment {
    variables = merge(
      var.path_to_config == null ? {} : yamldecode(file(var.path_to_config)),
      var.environment_variables
    )
  }

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# cloudwatch group per lambda function
resource "aws_cloudwatch_log_group" "lambda-log" {
  name              = "/aws/lambda/${aws_lambda_function.psoxy-instance.function_name}"
  retention_in_days = var.log_retention_in_days

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name        = "PsoxyExec_${var.function_name}"
  description = "execution role for psoxy instance"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow",
        "Sid" : ""
      }
    ]
  })

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}

# NOTE: these are known at plan time, allowing all the locals below to also be known at plan time
#   (if you take region from lambda/role, terraform plan shows the IAM policy as 'Known after apply')
data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  # TODO : revisit; this is exploiting convention
  prefix = "${upper(replace(var.function_name, "-", "_"))}_"

  param_arn_prefix = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${local.prefix}"

  function_write_arns = [
    "${local.param_arn_prefix}*" # wildcard to match all params corresponding to this function
  ]

  function_read_arns = concat(
    [
      "${local.param_arn_prefix}*" # wildcard to match all params corresponding to this function
    ],
    var.global_parameter_arns
  )

  write_statements = [{
    Action = [
      "ssm:PutParameter"
    ]
    Effect   = "Allow"
    Resource = local.function_write_arns
  }]

  read_statements = [{
    Action = [
      "ssm:GetParameter*"
    ]
    Effect   = "Allow"
    Resource = local.function_read_arns
  }]

  policy_statements = concat(
    local.read_statements,
    local.write_statements
  )
}

resource "aws_iam_policy" "ssm_param_policy" {
  name        = "${var.function_name}_ssmParameters"
  description = "Allow SSM parameter access needed by ${var.function_name}"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : local.policy_statements
    }
  )

  lifecycle {
    ignore_changes = [
      tags
    ]
  }
}


resource "aws_iam_role_policy_attachment" "basic" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.ssm_param_policy.arn
}


output "function_arn" {
  value = aws_lambda_function.psoxy-instance.arn
}

output "function_name" {
  value = aws_lambda_function.psoxy-instance.function_name
}

output "iam_role_for_lambda_arn" {
  value = aws_iam_role.iam_for_lambda.arn
}

output "iam_role_for_lambda_name" {
  value = aws_iam_role.iam_for_lambda.name
}

output "log_group" {
  value = aws_cloudwatch_log_group.lambda-log.name
}
