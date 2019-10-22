resource "aws_iam_role" "lambda-task-role" {
  name = "lambda-task-role"

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

resource "aws_iam_role_policy" "lambda-task-policy" {
  name = "lambda-task-policy"
  role = "${aws_iam_role.lambda-task-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
                "dynamodb:*",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
      ],
      "Resource": [
                "${aws_dynamodb_table.tasks-dynamodb-table.arn}",
                "arn:aws:logs:*:*:*"
      ]
    }
  ]
}
EOF
}

resource "aws_cloudwatch_log_group" "lambda-task-loggroup" {
  name              = "/aws/lambda/lambda-task"
  retention_in_days = 7
}

resource "aws_lambda_function" "lambda-task" {
  filename      = "lambda-task.zip"
  function_name = "lambda-task"
  role          = "${aws_iam_role.lambda-task-role.arn}"
  handler       = "main"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("lambda-task.zip")}"

  runtime = "go1.x"

  environment {
    variables = {
      dynamo_table = "${aws_dynamodb_table.tasks-dynamodb-table.name}"
      region = "${data.aws_region.current.name}"
    }
  }
}
