provider "aws" {}

# Variables
variable "get_remarketing_tags_function_name" {
  type = "string"
}

variable "add_remarketing_tags_function_name" {
  type = "string"
}

variable "upload_remarketing_tags_function_name" {
  type = "string"
}

variable "stage" {
  type = "string"
}

variable "api_name" {}
variable "api_description" {}
variable "env" {}
variable "region" {}
variable "account_id" {}
variable "hosted_zone" {}



resource "aws_api_gateway_rest_api" "api_gateway_rest_api" {
  name        = "${var.api_name}"
  description = "${var.api_description}"
}

resource "aws_api_gateway_method_settings" "api_gateway_method_settings" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  stage_name  = "${aws_api_gateway_stage.remarketing_tags_service_api_gateway_stage.stage_name}"
  method_path = "*/*"

  settings {
    metrics_enabled    = true
    logging_level      = "INFO"
    data_trace_enabled = true
    caching_enabled    = true
    cache_ttl_in_seconds = 3600
    require_authorization_for_cache_control = true
    unauthorized_cache_control_header_strategy = "FAIL_WITH_403"
  }
}

resource "aws_api_gateway_resource" "account_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_rest_api.api_gateway_rest_api.root_resource_id}"
  path_part   = "account"
}

resource "aws_api_gateway_resource" "remarketing_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_resource.account_resource.id}"
  path_part   = "remarketing"
}

resource "aws_api_gateway_resource" "upload_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_resource.remarketing_resource.id}"
  path_part   = "upload"
}

resource "aws_api_gateway_resource" "ddc_id_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_resource.account_resource.id}"
  path_part   = "{ddc_id}"
}

resource "aws_api_gateway_resource" "ddc_id_remarketing_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_resource.ddc_id_resource.id}"
  path_part   = "remarketing"
}

resource "aws_api_gateway_resource" "ddc_id_remarketing_tags_resource" {
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  parent_id   = "${aws_api_gateway_resource.ddc_id_remarketing_resource.id}"
  path_part   = "tags"
}

resource "aws_api_gateway_method" "get_remarketing_tags_method" {
  rest_api_id      = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  resource_id      = "${aws_api_gateway_resource.ddc_id_remarketing_tags_resource.id}"
  http_method      = "GET"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.querystring.ddc_id" = true
  }
}

resource "aws_api_gateway_method" "add_remarketing_tags_method" {
  rest_api_id      = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  resource_id      = "${aws_api_gateway_resource.ddc_id_remarketing_resource.id}"
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true

  request_parameters = {
    "method.request.querystring.ddc_id" = true
  }
}


resource "aws_api_gateway_method" "upload_remarketing_tags_method" {
  rest_api_id      = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  resource_id      = "${aws_api_gateway_resource.upload_resource.id}"
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

module "get_remarketing_tags_intergration" {
  providers = {
    aws = "aws"
  }

  source                  = "../remarketing-tags-service-api-gateway-integration"
  api_gateway_resource_id = "${aws_api_gateway_resource.ddc_id_remarketing_tags_resource.id}"
  http_method             = "${aws_api_gateway_method.get_remarketing_tags_method.http_method}"
  rest_api_id             = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  account_id              = "${var.account_id}"
  api_path                = "${aws_api_gateway_resource.ddc_id_remarketing_tags_resource.path}"
  region                  = "${var.region}"
  function_name           = "${var.get_remarketing_tags_function_name}"
}

module "add_remarketing_tags_integration" {
  providers = {
    aws = "aws"
  }

  source                  = "../remarketing-tags-service-api-gateway-integration"
  api_gateway_resource_id = "${aws_api_gateway_resource.ddc_id_remarketing_resource.id}"
  http_method             = "${aws_api_gateway_method.add_remarketing_tags_method.http_method}"
  rest_api_id             = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  region                  = "${var.region}"
  account_id              = "${var.account_id}"
  api_path                = "${aws_api_gateway_resource.ddc_id_remarketing_resource.path}"
  function_name           = "${var.add_remarketing_tags_function_name}"
}


module "upload_remarketing_tags_integration" {
  providers = {
    aws = "aws"
  }

  source                  = "../remarketing-tags-service-api-gateway-integration"
  api_gateway_resource_id = "${aws_api_gateway_resource.upload_resource.id}"
  http_method             = "${aws_api_gateway_method.upload_remarketing_tags_method.http_method}"
  rest_api_id             = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  region                  = "${var.region}"
  account_id              = "${var.account_id}"
  api_path                = "${aws_api_gateway_resource.upload_resource.path}"
  function_name           = "${var.upload_remarketing_tags_function_name}"
}

resource "aws_api_gateway_api_key" "api_gateway_api_key" {
  name = "adv-remarketing-tags-service-key-${var.env}"
}

resource "aws_api_gateway_usage_plan" "remarketing_tags_service_usage_plan" {
  name        = "adv-remarketing-tags-service-usage-plan"
  description = "Remarketing tags service api gateway usage plan"

  api_stages {
    api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
    stage  = "${aws_api_gateway_stage.remarketing_tags_service_api_gateway_stage.stage_name}"
  }
}

resource "aws_api_gateway_usage_plan_key" "remarketing_tags_service_usage_plan_key" {
  key_id        = "${aws_api_gateway_api_key.api_gateway_api_key.id}"
  key_type      = "API_KEY"
  usage_plan_id = "${aws_api_gateway_usage_plan.remarketing_tags_service_usage_plan.id}"
}

resource "aws_api_gateway_deployment" "api_gateway_deployment" {
  depends_on  = ["module.get_remarketing_tags_intergration", "module.add_remarketing_tags_integration", "module.upload_remarketing_tags_integration"]
  rest_api_id = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  variables = {
    "aliasName" = "RUNNING"
  }
  stage_name = "stagename-temp"
}

resource "aws_api_gateway_stage" "remarketing_tags_service_api_gateway_stage" {
  stage_name    = "${var.stage}"
  rest_api_id   = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  deployment_id = "${aws_api_gateway_deployment.api_gateway_deployment.id}"
  cache_cluster_enabled = true
  cache_cluster_size = "0.5"
}


module "api_gateway_domain_config" {
  source      = "../../../../components/api-gateway-custom-domain-with-endpoints"
  api_id      = "${aws_api_gateway_rest_api.api_gateway_rest_api.id}"
  hosted_zone = "${var.hosted_zone}"
  stage_name  = "${var.stage}"
  domain_name = "adv-remarketing-tags-service.${var.hosted_zone}"

  providers = {
    aws = "aws"
  }
}

output "get_remarketing_tags_rest_api_source_arn" {
  value = "${module.get_remarketing_tags_intergration.apigw_rest_api_source_arn}"
}

output "add_remarketing_tags_rest_api_source_arn" {
  value = "${module.add_remarketing_tags_integration.apigw_rest_api_source_arn}"
}

output "upload_remarketing_tags_rest_api_source_arn" {
  value = "${module.upload_remarketing_tags_integration.apigw_rest_api_source_arn}"
}
