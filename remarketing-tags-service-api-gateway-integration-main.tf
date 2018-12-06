provider "aws" {}

variable "region" {
  type = "string"
}

variable "account_id" {
  type = "string"
}

variable "rest_api_id" {
  type = "string"
}

variable "api_gateway_resource_id" {
  type = "string"
}

variable "http_method" {
  type = "string"
}

variable "function_name" {
  type = "string"
}

variable "api_path" {
  type = "string"
}

resource "aws_api_gateway_method_response" "200" {
  rest_api_id = "${var.rest_api_id}"
  resource_id = "${var.api_gateway_resource_id}"
  http_method = "${var.http_method}"
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_200_response" {
  rest_api_id = "${var.rest_api_id}"
  resource_id = "${var.api_gateway_resource_id}"
  http_method = "${var.http_method}"
  status_code = "${aws_api_gateway_method_response.200.status_code}"

  depends_on = ["aws_api_gateway_integration.apigw_integration"]
}

resource "aws_api_gateway_integration" "apigw_integration" {
  rest_api_id             = "${var.rest_api_id}"
  resource_id             = "${var.api_gateway_resource_id}"
  http_method             = "${var.http_method}"
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/arn:aws:lambda:${var.region}:${var.account_id}:function:${var.function_name}/invocations"
}

output "apigw_rest_api_source_arn" {
  value = "arn:aws:execute-api:${var.region}:${var.account_id}:${var.rest_api_id}/*/${var.http_method}${var.api_path}"
}
