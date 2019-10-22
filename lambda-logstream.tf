resource "aws_iam_role" "lambda-logstream-role" {
  name = "lambda-logstream-role"

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

resource "aws_iam_role_policy" "lambda-logstream-policy" {
  name = "lambda-logstream-policy"
  role = "${aws_iam_role.lambda-logstream-role.id}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
  "Effect": "Allow",
            "Action": [
                "es:*",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:CreateLogGroup"
            ],
            "Resource": [
                "${aws_elasticsearch_domain.elasticlog.arn}",
                "arn:aws:logs:*:*:*"
            ]
    }
  ]
}
EOF
}

resource "aws_lambda_function" "lambda-logstream" {
  filename      = "lambda-logstream.zip"
  function_name = "lambda-logstream"
  role          = "${aws_iam_role.lambda-logstream-role.arn}"
  handler       = "index.handler"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  source_code_hash = "${filebase64sha256("lambda-logstream.zip")}"

  runtime = "nodejs10.x"

    environment {
    variables = {
      es_endpoint = "${aws_elasticsearch_domain.elasticlog.endpoint}"
    }
  }

}
