resource "aws_iam_role" "lambda-authorizer-role" {
  name = "lambda-authorizer-role"

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

resource "aws_iam_role_policy" "lambda-authorizer-policy" {
  name = "lambda-authorizer-policy"
  role = "${aws_iam_role.lambda-authorizer-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
            "Effect": "Allow",
            "Action": [
                "execute-api:Invoke",
                "execute-api:ManageConnections"
            ],
            "Resource": "arn:aws:execute-api:*:*:*"      
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda-authorizer" {
  filename      = "lambda-authorizer.zip"
  function_name = "lambda-authorizer"
  role          = "${aws_iam_role.lambda-authorizer-role.arn}"
  handler       = "index.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("lambda-authorizer.zip")}"

  runtime = "nodejs10.x"

  environment {
    variables = {
      basic_username = "admin"
      basic_password = "secret"
    }
  }

}
