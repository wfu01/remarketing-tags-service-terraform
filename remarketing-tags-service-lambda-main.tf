variable "iam_role_arn" {
  type = "string"
}

variable "zip_key" {
  type = "string"
}

variable "function_name" {
  type = "string"
}

variable "handler" {
  type = "string"
}

variable "apigw_rest_api_source_arn" {
  type = "string"
}

resource "aws_lambda_function" "remarketing_tags_service_lambda_function" {
  function_name = "${var.function_name}"
  runtime       = "python3.6"
  filename      = "${substr(var.zip_key, length(path.cwd) + 1, -1)}"
  handler       = "${var.handler}"
  memory_size   = "1024"
  role          = "${var.iam_role_arn}"
  timeout       = 60
}

resource "aws_lambda_permission" "apigw_lambda_integration" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${var.function_name}"
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.apigw_rest_api_source_arn}"
  depends_on    = ["aws_lambda_function.remarketing_tags_service_lambda_function"]
}
