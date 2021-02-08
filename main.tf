terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = var.region
}

### Basic lambda iam role

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


## Cloudwatch IAM access

resource "aws_lambda_permission" "allow_cloudwatch_to_call_lambda" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.lambda.function_name
    principal = "events.amazonaws.com"
    source_arn = aws_cloudwatch_event_rule.once_a_day.arn
}


## Cloudwatch logs 

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

### Dynamo DB Table

resource "aws_dynamodb_table" "dynamodb_table" {
  name           = var.dynamo_table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "Name"

  attribute {
    name = "Name"
    type = "S"
  }
}

resource "aws_iam_policy" "lambda_dynamodb" {
  name        = "lambda_dynamodb"
  path        = "/"
  description = "IAM policy for accessing dynamodb from a lambda"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:GetItem"
      ],
      "Resource": "${aws_dynamodb_table.dynamodb_table.arn}",
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda_dynamodb" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_dynamodb.arn
}

### Create lambda packaging

resource "null_resource" "install_python_dependencies" {
    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "bash ${path.module}/scripts/create_pkg.sh"
        environment = {
            lambda_env         = var.lambda_env
            lambda_package_dir = var.lambda_package_dir
            path_module        = abspath(path.module)
            source_code_dir    = "../${var.source_code_dir}"
            runtime            = var.runtime
        }
    }
}

data "archive_file" "lambda_package_zip" {
    type        = "zip"
    source_dir  = "${path.module}/${var.lambda_package_dir}/"
    output_path = "${path.module}/${var.lambda_package_dir}.zip"

    depends_on = [null_resource.install_python_dependencies]
}

### Lambda function

resource "aws_lambda_function" "lambda" {
    description      = "Lambda function to deploy"
    filename         = data.archive_file.lambda_package_zip.output_path
    function_name    = var.function_name
    handler          = "${var.source_code_dir}.${var.function_name}.${var.handler_name}"
    role             = aws_iam_role.lambda_role.arn
    runtime          = var.runtime
    source_code_hash = data.archive_file.lambda_package_zip.output_base64sha256
    timeout          = var.timeout

    environment {
      variables = {
        LEAGUE_ID    = var.league_id
        THREAD_ID    = var.thread_id
        FB_EMAIL     = var.facebook_email
        FB_PASSWORD  = var.facebook_password
        FPL_EMAIL    = var.fpl_email
        FPL_PASSWORD = var.fpl_password
        DYNAMO_TABLE = var.dynamo_table_name
      }
    }
    depends_on = [aws_cloudwatch_log_group.lambda_log_group]

}

### Cron scheduler

resource "aws_cloudwatch_event_rule" "once_a_day" {
    name                = "lambda_scheduler"
    description         = "Schedule events for lambda, 9AM each day"
    schedule_expression = "cron(15 10 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_scheduler_target" {
    rule =  aws_cloudwatch_event_rule.once_a_day.name
    arn  =   aws_lambda_function.lambda.arn
}


### Cleanup lambda packaging

resource "null_resource" "cleanup_packaging" {
    triggers = {
        always_run = timestamp()
    }

    provisioner "local-exec" {
        command = "bash ${path.module}/scripts/cleanup_pkg.sh"
        environment = {
            lambda_env         = var.lambda_env
            lambda_package_dir = var.lambda_package_dir
            lambda_package_zip = "${var.lambda_package_dir}.zip"
            path_module        = abspath(path.module)
        }
    }

    depends_on = [aws_lambda_function.lambda]
}
