resource "aws_cloudwatch_log_subscription_filter" "lambdafunction_logstream" {
  depends_on = ["aws_lambda_permission.cloudwatch_allow"]
  name            = "test_lambdafunction_logfilter"
  log_group_name  = "${aws_cloudwatch_log_group.lambda-task-loggroup.name}"
  filter_pattern  = ""
  destination_arn = "${aws_lambda_function.lambda-logstream.arn}"
}

resource "aws_lambda_permission" "cloudwatch_allow" {
  statement_id = "cloudwatch_allow"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda-logstream.arn}"
  principal = "logs.eu-west-1.amazonaws.com"
  source_arn = "${aws_cloudwatch_log_group.lambda-task-loggroup.arn}"
}