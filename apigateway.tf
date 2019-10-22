resource "aws_api_gateway_rest_api" "task-api" {
  name        = "task-api"
  description = "Task API"
}

resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = "${aws_api_gateway_rest_api.task-api.id}"
  parent_id   = "${aws_api_gateway_rest_api.task-api.root_resource_id}"
  path_part   = "taskapi"
}


// Authorizer

resource "aws_api_gateway_gateway_response" "basicauth" {
  rest_api_id   = "${aws_api_gateway_rest_api.task-api.id}"
  status_code   = "401"
  response_type = "UNAUTHORIZED"

  response_templates = {
    "application/json" = "{'message':$context.error.messageString}"
  }

  response_parameters = {
    "gatewayresponse.header.Authorization" = "'Basic'"
  }
}

resource "aws_api_gateway_authorizer" "authorizer" {
  name                   = "authorizer"
  rest_api_id            = "${aws_api_gateway_rest_api.task-api.id}"
  authorizer_uri         = "${aws_lambda_function.lambda-authorizer.invoke_arn}"
  authorizer_credentials = "${aws_iam_role.invocation_role.arn}"
  type                   = "REQUEST"
}

resource "aws_iam_role" "invocation_role" {
  name = "api_gateway_auth_invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "invocation_policy" {
  name = "default"
  role = "${aws_iam_role.invocation_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": [
        "${aws_lambda_function.lambda-authorizer.arn}",
        "${aws_lambda_function.lambda-task.arn}"
      ]
    }
  ]
}
EOF
}


//


resource "aws_api_gateway_method" "proxy-get" {
  rest_api_id   = "${aws_api_gateway_rest_api.task-api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "proxy-post" {
  rest_api_id   = "${aws_api_gateway_rest_api.task-api.id}"
  resource_id   = "${aws_api_gateway_resource.proxy.id}"
  http_method   = "POST"
  authorization = "CUSTOM"
  authorizer_id = "${aws_api_gateway_authorizer.authorizer.id}"
}

resource "aws_api_gateway_integration" "lambda-get" {
  rest_api_id = "${aws_api_gateway_rest_api.task-api.id}"
  resource_id = "${aws_api_gateway_method.proxy-get.resource_id}"
  http_method = "${aws_api_gateway_method.proxy-get.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda-task.invoke_arn}"
}

resource "aws_api_gateway_integration" "lambda-post" {
  rest_api_id = "${aws_api_gateway_rest_api.task-api.id}"
  resource_id = "${aws_api_gateway_method.proxy-post.resource_id}"
  http_method = "${aws_api_gateway_method.proxy-post.http_method}"

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "${aws_lambda_function.lambda-task.invoke_arn}"
}


resource "aws_api_gateway_deployment" "task-api-deploy" {
  depends_on = [
    "aws_api_gateway_integration.lambda-get",
    "aws_api_gateway_integration.lambda-post"
  ]

  rest_api_id = "${aws_api_gateway_rest_api.task-api.id}"
  stage_name  = "demo"
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda-task.function_name}"
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.task-api.execution_arn}/*/*"
}

output "api_endpoint" {
  value       =  "${aws_api_gateway_deployment.task-api-deploy.invoke_url}"
  description = "The public API endopint."
}